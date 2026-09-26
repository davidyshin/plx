import { FormEvent, useEffect, useMemo, useState } from "react";
import {
  CheckCircle2,
  Check,
  BookOpen,
  ChevronDown,
  Crosshair,
  HeartPulse,
  Loader2,
  LogIn,
  LogOut,
  Plus,
  Shield,
  Swords,
  Trash2,
  Users,
} from "lucide-react";
import {
  AVAILABILITY,
  CLASS_COLORS,
  CLASS_RACES,
  CLASS_ROLES,
  ICONS,
  RACE_ICONS,
  ROLES,
} from "./data";
import { configured, supabase } from "./supabase";

type Pref = {
  id: string;
  player_name: string;
  discord_name: string;
  discord_user_id: string | null;
  discord_avatar_url: string | null;
  class_name: string;
  race_name: string;
  role_name: string;
  priority: number;
  availability: string;
  notes: string;
  created_at: string;
};
const empty = {
  player_name: "",
  discord_name: "",
  discord_user_id: "",
  discord_avatar_url: "",
  class_name: "Warrior",
  race_name: "Orc",
  role_name: "Tank",
  priority: 1,
  availability: "Flexible",
  notes: "",
};
function RoleIcon({ role, size = 16 }: { role: string; size?: number }) {
  if (role === "Tank") return <Shield size={size} />;
  if (role === "Healer") return <HeartPulse size={size} />;
  if (role === "Melee DPS") return <Swords size={size} />;
  return <Crosshair size={size} />;
}

function IconSelect({
  value,
  options,
  icons,
  onChange,
  label,
}: {
  value: string;
  options: string[];
  icons: Record<string, string>;
  onChange: (value: string) => void;
  label: string;
}) {
  const [expanded, setExpanded] = useState(false);
  return (
    <div className={`icon-select ${expanded ? "expanded" : ""}`}>
      <button
        type="button"
        className="icon-select-trigger"
        aria-haspopup="listbox"
        aria-expanded={expanded}
        aria-label={label}
        onClick={() => setExpanded(!expanded)}
      >
        <img src={icons[value]} alt="" />
        <span>{value}</span>
        <ChevronDown size={16} />
      </button>
      {expanded && (
        <div className="icon-select-menu" role="listbox" tabIndex={-1}>
          {options.map((option) => (
            <button
              type="button"
              role="option"
              aria-selected={option === value}
              key={option}
              onClick={() => {
                onChange(option);
                setExpanded(false);
              }}
            >
              <img src={icons[option]} alt="" />
              <span>{option}</span>
              {option === value && <Check size={15} />}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

export default function App() {
  const [discordConnected, setDiscordConnected] = useState(false);
  const [rows, setRows] = useState<Pref[]>([]),
    [form, setForm] = useState(empty),
    [loading, setLoading] = useState(true),
    [saving, setSaving] = useState(false),
    [open, setOpen] = useState(false),
    [summaryOpen, setSummaryOpen] = useState(false),
    [expandedPlayer, setExpandedPlayer] = useState<string | null>(null),
    [message, setMessage] = useState(""),
    [confirmation, setConfirmation] = useState("");
  useEffect(() => {
    if (!confirmation) return;
    const timer = window.setTimeout(() => setConfirmation(""), 4500);
    return () => window.clearTimeout(timer);
  }, [confirmation]);
  async function load() {
    if (!supabase) {
      setLoading(false);
      return;
    }
    const { data } = await supabase
      .from("guild_preferences")
      .select("*")
      .order("priority")
      .order("created_at", { ascending: false });
    setRows(data || []);
    setLoading(false);
  }
  useEffect(() => {
    load();
    const client = supabase;
    if (!client) return;
    function applyDiscordUser(user: {
      id: string;
      user_metadata: Record<string, string>;
    } | null) {
      if (!user) {
        setDiscordConnected(false);
        setForm((f) => ({
          ...f,
          discord_name: "",
          discord_user_id: "",
          discord_avatar_url: "",
        }));
        return;
      }
      const name =
        user.user_metadata.full_name ||
        user.user_metadata.name ||
        user.user_metadata.user_name ||
        "discord user";
      setForm((f) => ({
        ...f,
        discord_name: name,
        discord_user_id: user.id,
        discord_avatar_url: user.user_metadata.avatar_url || "",
      }));
      setDiscordConnected(true);
      if (localStorage.getItem("plx-open-after-auth") === "yes") {
        localStorage.removeItem("plx-open-after-auth");
        setOpen(true);
      }
    }
    client.auth.getUser().then(({ data }) => {
      const user = data.user;
      applyDiscordUser(user);
    });
    const { data: authListener } = client.auth.onAuthStateChange(
      (_event, session) => applyDiscordUser(session?.user || null),
    );
    const channel = client
      .channel("roster")
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "guild_preferences" },
        load,
      )
      .subscribe();
    return () => {
      authListener.subscription.unsubscribe();
      client.removeChannel(channel);
    };
  }, []);
  const players = useMemo(
    () => new Set(rows.map((r) => r.player_name.toLowerCase())).size,
    [rows],
  );
  const roleCounts = useMemo(
    () =>
      ROLES.map((role) => ({
        role,
        count: rows.filter((r) => r.role_name === role).length,
      })),
    [rows],
  );
  const classCount = useMemo(
    () => new Set(rows.map((r) => r.class_name)).size,
    [rows],
  );
  const playerGroups = useMemo(() => {
    const groups = new Map<string, Pref[]>();
    rows.forEach((row) => {
      const key = row.discord_user_id || row.discord_name.toLowerCase();
      groups.set(key, [...(groups.get(key) || []), row]);
    });
    return [...groups.entries()].map(([key, preferences]) => ({
      key,
      preferences: preferences.sort((a, b) => a.priority - b.priority),
    }));
  }, [rows]);
  const usedPriorities = useMemo(
    () =>
      rows
        .filter((row) => row.discord_user_id === form.discord_user_id)
        .map((row) => row.priority),
    [rows, form.discord_user_id],
  );
  function requestEdit() {
    if (!discordConnected) return;
    const nextPriority = [1, 2, 3].find(
      (priority) => !usedPriorities.includes(priority),
    );
    if (!nextPriority) {
      setConfirmation("you already have three preferences");
      return;
    }
    setForm((current) => ({ ...current, priority: nextPriority }));
    setOpen(true);
  }
  function pickClass(class_name: string) {
    setForm((f) => ({
      ...f,
      class_name,
      race_name: CLASS_RACES[class_name][0],
      role_name: CLASS_ROLES[class_name][0],
    }));
  }
  async function connectDiscord() {
    if (!supabase) return;
    localStorage.setItem("plx-open-after-auth", "yes");
    const { error } = await supabase.auth.signInWithOAuth({
      provider: "discord",
      options: { redirectTo: window.location.origin },
    });
    if (error) {
      localStorage.removeItem("plx-open-after-auth");
      setConfirmation("discord sign-in could not be started");
    }
  }
  async function disconnectDiscord() {
    if (!supabase) return;
    await supabase.auth.signOut();
    setOpen(false);
  }
  async function submit(e: FormEvent) {
    e.preventDefault();
    if (!supabase || !discordConnected) return;
    if (usedPriorities.includes(form.priority)) {
      setMessage("that preference order is already in use");
      return;
    }
    setSaving(true);
    setMessage("");
    const { error } = await supabase
      .from("guild_preferences")
      .insert({ ...form, player_name: form.discord_name });
    setSaving(false);
    if (error) {
      setMessage(error.message);
      return;
    }
    setOpen(false);
    setConfirmation("preference added successfully");
    setForm({
      ...empty,
      discord_name: form.discord_name,
      discord_user_id: form.discord_user_id,
      discord_avatar_url: form.discord_avatar_url,
      priority: Math.min(form.priority + 1, 3),
    });
    await load();
  }
  async function remove(id: string) {
    if (!supabase || !discordConnected) return;
    await supabase.from("guild_preferences").delete().eq("id", id);
    await load();
  }

  return (
    <div className="app">
      <header>
        <a className="brand" href="#top">
          <span className="brandmark">p</span>
          <span>
            plx<small>world of warcraft</small>
          </span>
        </a>
        <nav>
          <a href="#roster">roster</a>
          <a href="#composition">composition</a>
          {discordConnected ? (
            <div className="account-actions">
              <div className="discord-profile">
                {form.discord_avatar_url && <img src={form.discord_avatar_url} alt="" />}
                <span>{form.discord_name}</span>
                <button onClick={disconnectDiscord} aria-label="Sign out">
                  <LogOut size={14} />
                </button>
              </div>
              <button className="unlocked" onClick={requestEdit}>
                <Plus size={15} /> add preference
              </button>
            </div>
          ) : (
            <button onClick={connectDiscord}>
              <LogIn size={15} /> sign in with discord
            </button>
          )}
        </nav>
      </header>
      <main id="top">
        <section className="hero">
          <div className="hero-copy">
            <span className="overline">guild roster • live</span>
            <h1>
              plx is
              <br />
              <em>for pros.</em>
            </h1>
            <div className="hero-actions">
              {discordConnected && (
                <button className="primary" onClick={requestEdit}>
                  <Plus size={18} /> add preference
                </button>
              )}
              <button className="summary-link" onClick={() => setSummaryOpen(true)}>
                <BookOpen size={17} /> availability summary
              </button>
              <a href="#roster">view roster</a>
            </div>
          </div>
          <div className="hero-panel">
            <span>current roster</span>
            <div>
              <b>{players || "0"}</b>
              <small>players</small>
            </div>
            <div>
              <b>{rows.length || "0"}</b>
              <small>preferences</small>
            </div>
            <div>
              <b>{classCount || "0"}</b>
              <small>classes</small>
            </div>
          </div>
        </section>
        <section className="content" id="roster">
          <div className="section-head">
            <div>
              <span className="overline">guild planning</span>
              <h2>roster preferences</h2>
            </div>
            {discordConnected && (
              <button className="outline" onClick={requestEdit}>
                <Plus size={16} /> add preference
              </button>
            )}
          </div>
          {!configured && (
            <div className="setup">
              <Shield />
              <div>
                <b>supabase not connected</b>
                <p>Add the required environment variables and redeploy.</p>
              </div>
            </div>
          )}
          {loading ? (
            <div className="empty">
              <Loader2 className="spin" /> loading roster
            </div>
          ) : rows.length === 0 ? (
            <div className="empty">
              <Users />
              <h3>no preferences yet</h3>
              {discordConnected && (
                <button className="outline" onClick={requestEdit}>
                  add the first
                </button>
              )}
            </div>
          ) : (
            <div className="roster">
              {playerGroups.map(({ key, preferences }) => {
                const player = preferences[0];
                const expanded = expandedPlayer === key;
                return (
                  <article className={`player-group ${expanded ? "expanded" : ""}`} key={key}>
                    <button
                      className="player-summary"
                      onClick={() => setExpandedPlayer(expanded ? null : key)}
                      aria-expanded={expanded}
                    >
                      {player.discord_avatar_url ? (
                        <img src={player.discord_avatar_url} alt="" />
                      ) : (
                        <span className="avatar-fallback">{player.discord_name.slice(0, 1)}</span>
                      )}
                      <span className="player-name">
                        <b>{player.discord_name}</b>
                        <small>{preferences.length} {preferences.length === 1 ? "preference" : "preferences"}</small>
                      </span>
                      <span className="class-stack">
                        {preferences.map((preference) => (
                          <img key={preference.id} src={ICONS[preference.class_name]} alt={preference.class_name} />
                        ))}
                      </span>
                      <ChevronDown size={18} />
                    </button>
                    {expanded && (
                      <div className="preference-list">
                        {preferences.map((r) => (
                          <div className="preference-row" key={r.id}>
                            <div className="class-portrait" style={{ "--class": CLASS_COLORS[r.class_name] } as React.CSSProperties}>
                              <img src={ICONS[r.class_name]} alt={`${r.class_name} icon`} />
                              <span>{r.priority}</span>
                            </div>
                            <div className="identity">
                              <small>{r.race_name}</small>
                              <h3>{r.class_name}</h3>
                            </div>
                            <div className="role"><RoleIcon role={r.role_name} /><span>{r.role_name}</span></div>
                            <div className="availability"><small>availability</small><span>{r.availability}</span></div>
                            {r.notes && <p className="notes">{r.notes}</p>}
                            {discordConnected && r.discord_user_id === form.discord_user_id && (
                              <button className="delete" aria-label={`Remove ${r.class_name} preference`} onClick={() => remove(r.id)}>
                                <Trash2 size={16} />
                              </button>
                            )}
                          </div>
                        ))}
                      </div>
                    )}
                  </article>
                );
              })}
            </div>
          )}
        </section>
        <section className="composition" id="composition">
          <div className="section-head">
            <div>
              <span className="overline">at a glance</span>
              <h2>role composition</h2>
            </div>
          </div>
          <div className="role-grid">
            {roleCounts.map((item) => (
              <article key={item.role}>
                <span className="role-icon">
                  <RoleIcon role={item.role} size={22} />
                </span>
                <div>
                  <b>{item.count}</b>
                  <small>{item.role}</small>
                </div>
              </article>
            ))}
          </div>
        </section>
      </main>
      <footer>
        <div className="brand">
          <span className="brandmark">p</span>
          <span>plx</span>
        </div>
        <p>plx is for pros.</p>
        <span>not affiliated with blizzard entertainment</span>
      </footer>
      {summaryOpen && (
        <div
          className="modal"
          onMouseDown={(e) => {
            if (e.target === e.currentTarget) setSummaryOpen(false);
          }}
        >
          <section className="availability-summary" aria-modal="true" role="dialog">
            <button type="button" className="close" onClick={() => setSummaryOpen(false)}>×</button>
            <span className="overline">wow forever • horde</span>
            <h2>class / spec availability</h2>
            <div className="availability-grid">
              {Object.keys(CLASS_RACES).map((className) => {
                const classPicks = rows.filter((row) => row.class_name === className);
                return (
                  <article key={className}>
                    <div className="summary-class">
                      <img src={ICONS[className]} alt="" />
                      <b>{className}</b>
                      <small>{classPicks.length ? `${classPicks.length} selected` : "unselected"}</small>
                    </div>
                    <div className="summary-specs">
                      {CLASS_ROLES[className].map((spec) => {
                        const picks = classPicks.filter((row) => row.role_name === spec);
                        return (
                          <div className={`spec-coverage ${picks.length ? "chosen" : "open"}`} key={spec}>
                            <div className="spec-name">
                              <RoleIcon role={spec} size={16} />
                              <b>{spec}</b>
                              <small>{picks.length ? `${picks.length} picked` : "open"}</small>
                            </div>
                            {picks.length > 0 && (
                              <div className="spec-picks">
                                {picks.map((pick) => (
                                  <span key={pick.id}>
                                    {pick.discord_avatar_url && <img src={pick.discord_avatar_url} alt="" />}
                                    {pick.discord_name} <em>#{pick.priority}</em>
                                  </span>
                                ))}
                              </div>
                            )}
                          </div>
                        );
                      })}
                    </div>
                  </article>
                );
              })}
            </div>
          </section>
        </div>
      )}
      {open && (
        <div
          className="modal"
          onMouseDown={(e) => {
            if (e.target === e.currentTarget) setOpen(false);
          }}
        >
          <form onSubmit={submit}>
            <button
              type="button"
              className="close"
              onClick={() => setOpen(false)}
            >
              ×
            </button>
            <span className="overline">guild preference</span>
            <h2>add preference</h2>
            <div className="fields two">
              <label>
                class
                <IconSelect
                  value={form.class_name}
                  options={Object.keys(CLASS_RACES)}
                  icons={ICONS}
                  onChange={pickClass}
                  label="class"
                />
              </label>
              <label>
                race
                <IconSelect
                  value={form.race_name}
                  options={CLASS_RACES[form.class_name]}
                  icons={RACE_ICONS}
                  onChange={(race_name) => setForm({ ...form, race_name })}
                  label="race"
                />
              </label>
            </div>
            <div className="fields two">
              <label>
                role
                <select
                  value={form.role_name}
                  onChange={(e) =>
                    setForm({ ...form, role_name: e.target.value })
                  }
                >
                  {CLASS_ROLES[form.class_name].map((r) => (
                    <option key={r}>{r}</option>
                  ))}
                </select>
              </label>
              <label>
                preference order
                <select
                  value={form.priority}
                  onChange={(e) =>
                    setForm({ ...form, priority: +e.target.value })
                  }
                >
                  {[1, 2, 3].map((n) => (
                    <option key={n} value={n} disabled={usedPriorities.includes(n)}>
                      {n === 1 ? "1st choice" : n === 2 ? "2nd choice" : n === 3 ? "3rd choice" : `${n}th choice`}
                    </option>
                  ))}
                </select>
              </label>
            </div>
            <label>
              availability
              <select
                value={form.availability}
                onChange={(e) =>
                  setForm({ ...form, availability: e.target.value })
                }
              >
                {AVAILABILITY.map((a) => (
                  <option key={a}>{a}</option>
                ))}
              </select>
            </label>
            <label>
              notes <small>{form.notes.length}/180</small>
              <textarea
                maxLength={180}
                value={form.notes}
                onChange={(e) => setForm({ ...form, notes: e.target.value })}
                placeholder="spec, professions, experience…"
              />
            </label>
            {message && (
              <div className="message">
                <CheckCircle2 size={16} />
                {message}
              </div>
            )}
            <button className="primary submit" disabled={!configured || saving}>
              {saving ? <Loader2 className="spin" /> : <Plus />}{" "}
              {configured ? "add preference" : "supabase unavailable"}
            </button>
          </form>
        </div>
      )}
      {confirmation && (
        <div className="confirmation" role="status" aria-live="polite">
          <CheckCircle2 size={20} />
          <span>
            <b>{confirmation}</b>
          </span>
          <button
            type="button"
            onClick={() => setConfirmation("")}
            aria-label="Dismiss confirmation"
          >
            ×
          </button>
        </div>
      )}
    </div>
  );
}
