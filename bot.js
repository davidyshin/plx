require("dotenv").config();
const {
  Client,
  GatewayIntentBits,
  ActionRowBuilder,
  ButtonBuilder,
  EmbedBuilder,
} = require("discord.js");

const moment = require("moment");

const paddingtonQuotes = [
  "I don't do nothin' for no one for nothin'.",
  "You've literally just brought home a random bear.",
  "I am tickled the deepest shade of shrimp.",
  "Everyone is different, and that means anyone can fit in.",
  "Actors are some of the most evil, devious people on the planet. They lie for a living.",
  "My body aged quickly but for my heart, it took more time.",
  "You don't have to tell me about hard stares, I practically invented them.",
  "If we're kind and polite the world will be right.",
  "I may look like a hardened criminal, but I'm innocent.",
  "A wise bear always keeps a marmalade sandwich in his hat, in case of emergency.",
  "I'll never be like other people, but that's all right.",
];

let eventCreationSessions = {};

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent,
    GatewayIntentBits.GuildMessageReactions,
    GatewayIntentBits.DirectMessages,
  ],
});

client.once("ready", () => {
  console.log("Bot is online!");
});

client.login(process.env.BOT_TOKEN);

const { SlashCommandBuilder } = require("@discordjs/builders");
const { REST } = require("@discordjs/rest");
const { Routes } = require("discord-api-types/v9");

const createCommandData = new SlashCommandBuilder()
  .setName("create")
  .setDescription("Create a new event")
  .addStringOption((option) =>
    option
      .setName("title")
      .setDescription("Title of the event")
      .setRequired(true)
  );

const clientId = process.env.BOT_CLIENT_ID;
const guildId = process.env.BOT_GUILD_ID;
const commands = [createCommandData.toJSON()];

const rest = new REST({ version: "9" }).setToken(process.env.BOT_TOKEN);

(async () => {
  try {
    console.log("Started refreshing application (/) commands.");

    if (guildId) {
      await rest.put(Routes.applicationGuildCommands(clientId, guildId), {
        body: commands,
      });
    } else {
      await rest.put(Routes.applicationCommands(clientId), { body: commands });
    }

    console.log("Successfully reloaded application (/) commands.");
  } catch (error) {
    console.error(error);
  }
})();

client.on("interactionCreate", async (interaction) => {
  if (interaction.isCommand() && interaction.commandName === "create") {
    const title = interaction.options.getString("title");
    const userId = interaction.user.id;
    const channel = interaction.channel;

    if (eventCreationSessions[userId]) {
      await interaction.user.send(
        "You already have an event creation in progress."
      );
      return;
    }

    eventCreationSessions[userId] = {
      step: 1, // Step 1 is collecting the date
      title: title,
      channelId: channel.id,
      guildId: interaction.guildId,
      allAttendees: [],
    };

    await interaction.user.send(
      'Please enter the date for your event (e.g., "MM/DD"):'
    );
    await interaction.reply({
      content: "Check your DMs to continue creating the event.",
      ephemeral: true,
    });
  }

  if (interaction.isButton()) {
    const eventId = interaction.message.id;
    const eventSession = eventCreationSessions[eventId];
    const userId = interaction.user.id;

    if (!eventSession || !eventSession.attendees) return;

    // Check if user is already signed up for a role
    if (interaction.customId === "🚫") {
      // Remove user from all roles and allAttendees list
      Object.values(eventSession.attendees).forEach((roleArray) => {
        const index = roleArray.indexOf(userId);
        if (index > -1) {
          roleArray.splice(index, 1);
        }
      });
      const allAttendeesIndex = eventSession.allAttendees.indexOf(userId);
      if (allAttendeesIndex > -1) {
        eventSession.allAttendees.splice(allAttendeesIndex, 1);
      }
    } else {
      // Determine the role selected by the user
      const selectedRole = interaction.customId; // 'dps', 'healer', or 'tank'

      // Remove the user from any role they are currently signed up for
      Object.keys(eventSession.attendees).forEach((role) => {
        const index = eventSession.attendees[role].indexOf(userId);
        if (index > -1) {
          eventSession.attendees[role].splice(index, 1);
        }
      });

      // Add the user to the selected role
      if (!eventSession.attendees[selectedRole].includes(userId)) {
        eventSession.attendees[selectedRole].push(userId);
      }

      if (!eventSession.allAttendees.includes(userId)) {
        eventSession.allAttendees.push(userId);
      }
    }

    const eventDateTime = moment(
      `${moment().year()}-${eventSession.date} ${eventSession.time}`,
      "YYYY-MM/DD HH:mm a"
    ).format("MMMM Do YYYY, h:mm a");

    const guild = client.guilds.cache.get(process.env.BOT_GUILD_ID);

    const getDisplayNameWithOrder = async (userId) => {
      const member = await guild.members.fetch(userId).catch(() => null);
      const displayName = member ? member.displayName : "Unknown Member";
      return `${displayName}`;
    };

    const generateRoleField = async (roleArray) => {
      const namesWithOrder = await Promise.all(
        roleArray.map(getDisplayNameWithOrder)
      );
      return namesWithOrder.join("\n") || "None";
    };

    const tankField = await generateRoleField(eventSession.attendees.tank);
    const healerField = await generateRoleField(eventSession.attendees.healer);
    const dpsField = await generateRoleField(eventSession.attendees.dps);
    console.log("Nice");

    const eventEmbed = new EmbedBuilder()
      .setColor("#e90303")
      .setTitle(eventSession.title)
      .setThumbnail(
        "https://media1.giphy.com/media/xUNda0CcstnPUkjZcY/giphy.gif?cid=ecf05e47hz5cqpbpfgw133vjeg2fq5ojoudj1nj2hshia4us&ep=v1_gifs_search&rid=giphy.gif&ct=g"
      )
      .setDescription(`Scheduled for ${eventDateTime} (Eastern Time)`)
      .addFields({
        name: "Total Signed Up",
        value: eventSession.allAttendees.length.toString(),
        inline: true,
      })
      .addFields({
        name: "🛡",
        value: !!eventSession.attendees.tank.length ? tankField : "None",
        inline: false,
      })
      .addFields({
        name: "💉",
        value: !!eventSession.attendees.healer.length ? healerField : "None",
        inline: false,
      })
      .addFields({
        name: "⚔️",
        value: !!eventSession.attendees.dps.length ? dpsField : "None",
        inline: false,
      })
      .addFields({ name: "\u200B", value: "\u200B" })
      .setFooter({ text: paddingtonQuotes[eventSession.quoteIndex] });
    await interaction.update({
      embeds: [eventEmbed],
      components: interaction.message.components,
    });
  }
});

client.on("messageCreate", async (message) => {
  // Log every message for debugging
  console.log("Message received: ", message.content);
  if (message.author.bot) return;
  if (message.channel.type !== 1) return;

  console.log("Received DM:", message.content); // Debugging line

  const session = eventCreationSessions[message.author.id];
  if (!session) return;

  // Handle date input
  if (session.step === 1) {
    // Process date input and ask for time
    const inputDate = moment(message.content, "MM/DD");
    if (!inputDate.isValid()) {
      await message.author.send(
        "Invalid date format. Please enter the date again (e.g., 'MM/DD'):"
      );
      return;
    }

    session.date = inputDate.format("MM/DD");
    session.step = 2;
    await message.author.send(
      'Please enter the time for your event (e.g., "HH:MM am/pm"):'
    );
  }
  // Handle time input
  else if (session.step === 2) {
    // Process time input and create event
    const inputTime = moment(message.content, "HH:mm a");
    if (!inputTime.isValid()) {
      await message.author.send(
        "Invalid time format. Please enter the time again (e.g., 'HH:MM am/pm'):"
      );
      return;
    }

    session.time = inputTime.format("HH:mm a");

    session.time = message.content;
    const eventDateTime = moment(
      `${moment().year()}-${session.date} ${session.time}`,
      "YYYY-MM/DD HH:mm a"
    ).format("MMMM Do YYYY, h:mm a");

    const row = new ActionRowBuilder().addComponents(
      new ButtonBuilder().setCustomId("tank").setLabel("🛡").setStyle("Primary"),
      new ButtonBuilder()
        .setCustomId("healer")
        .setLabel("💉")
        .setStyle("Primary"),
      new ButtonBuilder().setCustomId("dps").setLabel("⚔️").setStyle("Primary"),
      new ButtonBuilder().setCustomId("🚫").setLabel("🚫").setStyle("Danger")
    );

    const quoteIndex = Math.floor(Math.random() * paddingtonQuotes.length);

    // Inside the button interaction logic

    const eventEmbed = new EmbedBuilder()
      .setColor("#e90303")
      .setTitle(session.title)
      .setThumbnail(
        "https://media1.giphy.com/media/xUNda0CcstnPUkjZcY/giphy.gif?cid=ecf05e47hz5cqpbpfgw133vjeg2fq5ojoudj1nj2hshia4us&ep=v1_gifs_search&rid=giphy.gif&ct=g"
      )
      .setDescription(`Scheduled for ${eventDateTime} (Eastern Time)`)
      .addFields({ name: "Total Signed Up", value: "0", inline: false })
      .addFields({
        name: "🛡",
        value: "None",
        inline: false,
      })
      .addFields({
        name: "💉",
        value: "None",
        inline: false,
      })
      .addFields({
        name: "⚔️",
        value: "None",
        inline: false,
      })
      .addFields({ name: "\u200B", value: "\u200B" })
      .setFooter({ text: paddingtonQuotes[quoteIndex] });

    // Send the event embed to the original channel
    const originalChannel = await client.channels.fetch(session.channelId);
    const eventMessage = await originalChannel.send({
      embeds: [eventEmbed],
      components: [row],
    });

    eventCreationSessions[eventMessage.id] = {
      title: session.title,
      date: session.date,
      time: session.time,
      quoteIndex,
      attendees: {
        dps: [],
        healer: [],
        tank: [],
      },
      allAttendees: [],
    };

    delete eventCreationSessions[message.author.id]; // Cleanup session
    await message.author.send("Event created successfully!");
  }
});
