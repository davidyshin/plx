import { FormEvent, useEffect, useMemo, useState } from "react";
import {
  CheckCircle2,
  Crosshair,
  HeartPulse,
  Loader2,
  LockKeyhole,
  Plus,
  Shield,
  Swords,
  Trash2,
  Users,
} from "lucide-react";
import { AVAILABILITY, CLASS_COLORS, CLASS_RACES, ICONS, ROLES } from "./data";
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
const sitePassword = import.meta.env.VITE_SITE_PASSWORD || "";

function RoleIcon({ role, size = 16 }: { role: string; size?: number }) {
  if (role === "Tank") return <Shield size={size} />;
  if (role === "Healer") return <HeartPulse size={size} />;
  if (role === "Melee DPS") return <Swords size={size} />;
  return <Crosshair size={size} />;
}

export default function App() {
  const [unlocked, setUnlocked] = useState(
    () => !sitePassword || localStorage.getItem("plx-edit-unlocked") === "yes",
  );
  const [password, setPassword] = useState(""),
    [passwordError, setPasswordError] = useState(false);
  const [discordConnected, setDiscordConnected] = useState(false);
  const [discordError, setDiscordError] = useState("");
  const [rows, setRows] = useState<Pref[]>([]),
    [form, setForm] = useState(empty),
    [loading, setLoading] = useState(true),
    [saving, setSaving] = useState(false),
    [open, setOpen] = useState(false),
    [authOpen, setAuthOpen] = useState(false),
    [message, setMessage] = useState("");
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
    client.auth.getUser().then(({ data }) => {
      const user = data.user;
      if (!user) return;
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
    });
    const channel = client
      .channel("roster")
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "guild_preferences" },
        load,
      )
      .subscribe();
    return () => {
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
  function requestEdit() {
    unlocked ? setOpen(true) : setAuthOpen(true);
  }
  function unlock(e: FormEvent) {
    e.preventDefault();
    if (password === sitePassword) {
      localStorage.setItem("plx-edit-unlocked", "yes");
      setUnlocked(true);
      setPasswordError(false);
      setAuthOpen(false);
      setOpen(true);
    } else {
      setPasswordError(true);
      setPassword("");
    }
  }
  function pickClass(class_name: string) {
    setForm((f) => ({
      ...f,
      class_name,
      race_name: CLASS_RACES[class_name][0],
    }));
  }
  async function connectDiscord() {
    if (!supabase) return;
    setDiscordError("");
    const { error } = await supabase.auth.signInWithOAuth({
      provider: "discord",
      options: { redirectTo: window.location.origin },
    });
    if (error) setDiscordError("discord connection is not configured yet");
  }
  async function submit(e: FormEvent) {
    e.preventDefault();
    if (!supabase || !unlocked) return;
    setSaving(true);
    setMessage("");
    const { error } = await supabase.from("guild_preferences").insert(form);
    setSaving(false);
    if (error) {
      setMessage(error.message);
      return;
    }
    setMessage("preference added");
    setForm({
      ...empty,
      player_name: form.player_name,
      discord_name: form.discord_name,
      priority: Math.min(form.priority + 1, 3),
    });
    await load();
  }
  async function remove(id: string) {
    if (!supabase || !unlocked) return;
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
          <button className={unlocked ? "unlocked" : ""} onClick={requestEdit}>
            {unlocked ? (
              <>
                <Plus size={15} /> add preference
              </>
            ) : (
              <>
                <LockKeyhole size={15} /> editor login
              </>
            )}
          </button>
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
              <button className="primary" onClick={requestEdit}>
                {unlocked ? <Plus size={18} /> : <LockKeyhole size={18} />}{" "}
                {unlocked ? "add preference" : "unlock editor"}
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
            <button className="outline" onClick={requestEdit}>
              {unlocked ? <Plus size={16} /> : <LockKeyhole size={16} />}{" "}
              {unlocked ? "add preference" : "unlock editor"}
            </button>
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
              {unlocked && (
                <button className="outline" onClick={() => setOpen(true)}>
                  add the first
                </button>
              )}
            </div>
          ) : (
            <div className="roster">
              {rows.map((r) => (
                <article
                  className="member"
                  key={r.id}
                  style={
                    {
                      "--class": CLASS_COLORS[r.class_name],
                    } as React.CSSProperties
                  }
                >
                  <div className="class-portrait">
                    <img
                      src={ICONS[r.class_name]}
                      alt={`${r.class_name} icon`}
                    />
                    <span>{r.priority}</span>
                  </div>
                  <div className="identity">
                    <small>
                      {r.race_name} {r.class_name}
                    </small>
                    <h3>{r.player_name}</h3>
                    {r.discord_name && (
                      <p className="discord-line">
                        {r.discord_avatar_url && (
                          <img src={r.discord_avatar_url} alt="" />
                        )}
                        @{r.discord_name}
                      </p>
                    )}
                  </div>
                  <div className="role">
                    <RoleIcon role={r.role_name} />
                    <span>{r.role_name}</span>
                  </div>
                  <div className="availability">
                    <small>availability</small>
                    <span>{r.availability}</span>
                  </div>
                  {r.notes && <p className="notes">{r.notes}</p>}
                  {unlocked && (
                    <button
                      className="delete"
                      aria-label={`Remove ${r.player_name}'s preference`}
                      onClick={() => remove(r.id)}
                    >
                      <Trash2 size={16} />
                    </button>
                  )}
                </article>
              ))}
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
      {authOpen && (
        <div
          className="modal"
          onMouseDown={(e) => {
            if (e.target === e.currentTarget) setAuthOpen(false);
          }}
        >
          <form className="auth-form" onSubmit={unlock}>
            <button
              type="button"
              className="close"
              onClick={() => setAuthOpen(false)}
            >
              ×
            </button>
            <span className="form-icon">
              <LockKeyhole />
            </span>
            <span className="overline">editor access</span>
            <h2>unlock roster</h2>
            <label>
              password
              <input
                autoFocus
                type="password"
                value={password}
                onChange={(e) => {
                  setPassword(e.target.value);
                  setPasswordError(false);
                }}
                aria-invalid={passwordError}
              />
            </label>
            {passwordError && (
              <span className="form-error">incorrect password</span>
            )}
            <button className="primary submit">unlock editor</button>
          </form>
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
            <span className="overline">roster editor</span>
            <h2>add preference</h2>
            <div className="fields two">
              <label>
                character
                <input
                  required
                  minLength={2}
                  maxLength={24}
                  value={form.player_name}
                  onChange={(e) =>
                    setForm({ ...form, player_name: e.target.value })
                  }
                  placeholder="character name"
                />
              </label>
              <label>
                discord profile
                <button
                  className={`discord-connect ${discordConnected ? "connected" : ""}`}
                  type="button"
                  onClick={connectDiscord}
                >
                  {discordConnected && form.discord_avatar_url ? (
                    <img src={form.discord_avatar_url} alt="" />
                  ) : (
                    <span className="discord-mark">◉</span>
                  )}
                  {discordConnected ? form.discord_name : "connect discord"}
                </button>
                {discordError && <span className="inline-error">{discordError}</span>}
              </label>
            </div>
            <div className="fields two">
              <label>
                class
                <select
                  value={form.class_name}
                  onChange={(e) => pickClass(e.target.value)}
                >
                  {Object.keys(CLASS_RACES).map((c) => (
                    <option key={c}>{c}</option>
                  ))}
                </select>
              </label>
              <label>
                race
                <select
                  value={form.race_name}
                  onChange={(e) =>
                    setForm({ ...form, race_name: e.target.value })
                  }
                >
                  {CLASS_RACES[form.class_name].map((r) => (
                    <option key={r}>{r}</option>
                  ))}
                </select>
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
                  {ROLES.map((r) => (
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
                    <option key={n} value={n}>
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
    </div>
  );
}
