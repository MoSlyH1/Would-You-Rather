// The 50 seed "Would You Rather" questions, grouped by category.
// Each raw string is parsed into { optionA, optionB } by splitting on the capitalized "OR".

const RAW = {
  Football: [
    "Would you rather win the Ballon d'Or but play for your club's biggest rival, OR win the Champions League with your current club but score 0 goals all season?",
    "Would you rather Messi in his prime join the Lebanese National Team for one World Cup qualifier, OR have a fully fit, 25-year-old Ronaldo play for Nejmeh SC for a full season?",
    "Would you rather your national team qualify for the World Cup but get beaten 10-0 in every match, OR never qualify but consistently beat Israel 5-0 in every friendly?",
    "Would you rather be a starting goalkeeper who concedes a howler in the World Cup final, OR be a benchwarmer who lifts the trophy but never plays a single minute?",
    "Would you rather have VAR review every single decision perfectly but stop the game for 5 minutes each time, OR have no VAR and accept blatant referee mistakes?",
    "Would you rather score a 90th-minute bicycle kick goal in the derby, OR assist the 90th-minute winner with a perfect nutmeg pass?",
    "Would you rather play on a pristine, wet grass pitch but in freezing rain, OR play on a dusty, dry concrete pitch but in 25°C sunshine?",
    "Would you rather Ronaldo's jump header power, OR Messi's low center of gravity and dribbling?",
    "Would you rather your club gets bought by a Saudi billionaire and wins everything (but loses its soul), OR stays fan-owned and fights relegation every year?",
    "Would you rather miss a penalty in a shootout that loses the final, OR get a red card in the first minute of the final and watch your team lose from the stands?",
  ],
  Lebanon: [
    "Would you rather have perfect, non-stop electricity (24/7) but absolutely no internet or cell signal, OR have perfect 5G internet but only 2 hours of electricity a day?",
    "Would you rather eat shawarma from your favorite street cart every day for a year, OR eat a 5-star gourmet meal once a month but it's always freekeh?",
    "Would you rather understand every Lebanese politician's true intentions, OR have the power to silence your neighbors' generator forever?",
    "Would you rather live in a beautiful, traditional Lebanese village but have to commute 3 hours to work, OR live in a tiny, cramped apartment in Beirut but be 5 minutes from everything?",
    "Would you rather give up tabbouleh forever, OR give up hummus forever?",
    "Would you rather have your entire family show up unannounced every Friday for lunch, OR never have anyone visit you ever again (but they call you daily)?",
    "Would you rather drive through Beirut traffic for 2 hours, OR walk up a steep mountain road in the summer heat for 2 hours?",
    "Would you rather always have fresh, warm mana'eesh for breakfast, OR always have cold, crisp Lebanese beer waiting for you after work?",
    "Would you rather understand all the Lebanese inside-jokes but speak terrible Arabic, OR speak fluent, poetic Arabic but never understand sarcasm?",
    "Would you rather live through the 1970s golden era of Lebanon, OR live in 2050 when Lebanon is completely rebuilt and modern?",
  ],
  "Lebanese Politics": [
    "Would you rather abolish the sectarian political system completely but risk total chaos for 5 years, OR keep the current system but guarantee zero corruption starting tomorrow?",
    "Would you rather have the Lebanese Lira become equal to the Dollar overnight but all salaries are cut by 80%, OR keep the current exchange rate but your salary doubles?",
    "Would you rather know exactly who stole every dollar from the Central Bank, OR get all your lost savings back but never know who took them?",
    "Would you rather be the President of Lebanon for one day with absolute dictatorial power, OR be the most respected civil activist for 20 years but with no political power?",
    "Would you rather Lebanon allies entirely with the West, OR allies entirely with the Eastern bloc—knowing either choice will make half the country hate you?",
    "Would you rather have garbage collection fixed permanently but pay triple the taxes, OR have perfect electricity but the garbage crisis gets 10x worse?",
    "Would you rather bring back the old Lebanese passport that got you no visas, OR keep the new powerful passport but have to renounce your Lebanese citizenship to use it?",
    "Would you rather every Lebanese politician is forced to take a lie detector test on live TV, OR every politician must live in the poorest neighborhood for one year?",
    "Would you rather have a unified, secular Lebanese army that answers to nobody but the people, OR have a weak army but incredibly powerful, independent local municipalities?",
    "Would you rather the next president is a brilliant technocrat with no charisma, OR a charismatic leader who knows nothing about economics?",
  ],
  Technology: [
    "Would you rather have unlimited, perfect AI that does your job for you, OR have the ability to permanently delete all social media algorithms from existence?",
    "Would you rather your smartphone battery never dies, OR your home WiFi never buffers or lags?",
    "Would you rather only be able to use emojis to communicate for a year (no words), OR only be able to use voice notes (no typing) for a year?",
    "Would you rather have a brain chip that lets you download any skill instantly, OR have an external device that lets you rewind and record your dreams?",
    "Would you rather your entire search history is leaked publicly, OR your entire private WhatsApp chats are leaked publicly?",
    "Would you rather own a perfect self-driving car, OR own a personal drone that delivers anything you want within 5 minutes?",
    "Would you rather all screens in the world turn black and white (no color), OR all screens become 480p resolution permanently?",
    "Would you rather never be able to use Google/YouTube again, OR never be able to use ChatGPT/AI tools again?",
    "Would you rather have a robotic exoskeleton that gives you super strength, OR have bionic eyes that give you 20/5 vision and thermal imaging?",
    "Would you rather your phone automatically corrects all your typos perfectly, OR your phone automatically generates the perfect witty reply to every text?",
  ],
  Food: [
    "Would you rather eat raw kibbeh every day for breakfast, OR eat raw fish (sushi) every day for dinner?",
    "Would you rather give up garlic forever (no toum, no garlic sauce), OR give up lemon juice forever (no fattoush, no lemon on grilled meat)?",
    "Would you rather only eat sweets for the rest of your life (baklava, knafeh, chocolate), OR only eat salty/savory food (meat, cheese, fries) forever?",
    "Would you rather your food is always perfectly seasoned but always served at room temperature, OR perfectly hot/cold but always slightly under-seasoned?",
    "Would you rather never eat bread again (no pita, no baguettes), OR never eat rice again (no hashweh, no biryani)?",
    "Would you rather drink a glass of pure olive oil every morning, OR drink a glass of pure lemon juice every morning?",
    "Would you rather all fast food becomes incredibly healthy but tastes bland, OR all healthy food tastes like your favorite junk food but has zero nutrients?",
    "Would you rather only be able to eat with your hands forever (no cutlery), OR only be able to eat with giant chopsticks forever?",
    "Would you rather your fridge is always stocked with fresh Lebanese produce, OR your pantry is always stocked with international luxury snacks (Japanese KitKats, American cereals)?",
    "Would you rather discover a new spice that makes every dish taste 10x better, OR discover a new cooking method that makes every dish cook in 2 minutes?",
  ],
};

function titleCase(s) {
  return s.charAt(0).toUpperCase() + s.slice(1);
}

// Split a raw "Would you rather A, OR B?" string into { optionA, optionB }.
function parseQuestion(raw) {
  let s = raw.trim();
  // strip leading "Would you rather "
  s = s.replace(/^would you rather\s+/i, "");
  // strip trailing "?"
  s = s.replace(/\?+\s*$/, "");
  // split on the capitalized standalone OR (optionally preceded by a comma/dash)
  const m = s.split(/\s*[,—-]?\s+OR\s+/);
  if (m.length !== 2) {
    throw new Error("Could not split into exactly 2 options: " + raw + " -> " + m.length);
  }
  return {
    optionA: titleCase(m[0].trim()),
    optionB: titleCase(m[1].trim()),
  };
}

// Flatten into a list of { category, optionA, optionB }
function getSeedQuestions() {
  const out = [];
  for (const [category, list] of Object.entries(RAW)) {
    for (const raw of list) {
      const { optionA, optionB } = parseQuestion(raw);
      out.push({ category, optionA, optionB });
    }
  }
  return out;
}

module.exports = { getSeedQuestions, parseQuestion, RAW };
