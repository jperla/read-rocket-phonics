import Foundation

struct Lesson: Identifiable, Hashable {
    let id: String
    let title: String
    let icon: String
    var words: [PWord] = []
    var sentences: [[String]] = []
    /// Pre-reader on-ramp content: single letters this lesson teaches, and which
    /// letter activities to run for each (see LetterLand). Empty for word lessons.
    var letters: [Letter] = []
    var letterActivities: [LetterActivity] = []
    /// True only in the end-of-curriculum spelling unit: the word challenge is
    /// ENCODING (build the word from its sounds). Everywhere else the challenge
    /// is reading-only — spelling is much harder and comes after mastery.
    var spell: Bool = false

    /// True when this is a pre-reader letter/sound lesson (no word blending).
    var isLetterLesson: Bool { !letters.isEmpty }

    /// The new sound this lesson introduces (a digraph, vowel team, magic-e long
    /// vowel, r-controlled vowel, …). Short-vowel CVC lessons return nil — the
    /// kids already know those letter sounds.
    var introGrapheme: Grapheme? {
        guard let first = words.first else { return nil }
        // A doubled consonant (gg, ll, ss…) is not a *new* sound — don't "teach" it.
        func isDoubled(_ s: String) -> Bool { s.count == 2 && Set(s).count == 1 }
        if let g = first.graphemes.first(where: {
            $0.letters.count > 1 && !$0.isSilent && !isDoubled($0.letters)
        }) {
            return g
        }
        if first.graphemes.contains(where: { $0.isSilent }),
           let vowel = first.graphemes.first(where: { !$0.isSilent && "aeiou".contains($0.letters) }) {
            return vowel
        }
        return nil
    }

}

struct Unit: Identifiable, Hashable {
    let id: String
    let title: String
    let colorA: String
    let colorB: String
    var lessons: [Lesson]
}

enum Curriculum {
    static var allLessons: [Lesson] { units.flatMap { $0.lessons } }
    static var lessonOrder: [String] { allLessons.map { $0.id } }
    /// Safe first lesson — never force-unwrapped. Falls back to an empty placeholder
    /// if the curriculum is ever empty, so previews / slice-mode can't crash.
    static var firstLesson: Lesson { allLessons.first ?? Lesson(id: "empty", title: "", icon: "") }
    static func unit(forLesson id: String) -> Unit? {
        units.first { $0.lessons.contains { $0.id == id } }
    }

    /// Find a decodable word anywhere in the curriculum by its text (for replaying
    /// review words pulled from the spaced-repetition queue).
    static func word(text: String) -> PWord? {
        for u in units { for l in u.lessons {
            if let w = l.words.first(where: { $0.text == text }) { return w }
        } }
        return nil
    }

    private static func w(_ text: String, _ tokens: [String], picture: String? = nil) -> PWord {
        Phonics.word(text, tokens, picture: picture)
    }

    // On-ramp: phonemic awareness + single letters → the BLENDING BRIDGE (blend 2
    // sounds, then first continuant-onset CVC words) → core CVC/phonics units →
    // extra word-family practice. The bridge keeps letters → whole-words gradual.
    //
    // The active language picks the curriculum: English is the full journey; other
    // packs (Greek) supply their own units. Reads the global Languages.current,
    // which the app keeps in sync with the selected profile's chosen language.
    static var units: [Unit] {
        switch Languages.current {
        case "el": return GreekLand.units
        case "es": return SpanishLand.units
        case "fr": return FrenchLand.units
        case "pt": return PortugueseLand.units
        case "de": return GermanLand.units
        case "pt-PT": return PortugueseLand.euUnits
        case "en-GB": return EnglishUKLand.units
        default:   return englishUnits
        }
    }
    private static let englishUnits: [Unit] = {
        // Core word units get generated PRACTICE LAPS (repeat + cumulative mix);
        // WordFamilies is already a drill block, so it stays as-is.
        let core = ReviewLessons.withPracticeLaps(coreUnits, practiceTitle: "Practice!",
                                                  mixTitle: "Mix it up!")
        var u = LetterLand.units + Blending.units + core + WordFamilies.units
        // Spelling LAST (encoding ≫ harder than decoding): early CVC words,
        // spelled from sound only after the whole reading journey.
        let early = coreUnits.prefix(3).flatMap { $0.lessons }.flatMap { $0.words }
        if let spell = ReviewLessons.spellingUnit(idPrefix: "en", title: "Spell it!", words: early) {
            u.append(spell)
        }
        return u
    }()

    /// "Today's Review": a lesson generated from THIS child's own history
    /// (recently missed word texts first, plus mastered ones due for a refresh).
    /// Personalized repetition — nil until there's enough history to drill.
    static func dailyReview(missed: [String], mastered: [String]) -> Lesson? {
        let words = (missed + mastered).compactMap { word(text: $0) }
        guard words.count >= 3 else { return nil }
        return Lesson(id: "daily_review", title: Languages.active.t("daily_review"),
                      icon: "⭐", words: words)
    }

    private static let coreUnits: [Unit] = [
        // MARK: Unit 1 — short a
        Unit(id: "u1", title: "Short a", colorA: "#FF9A6B", colorB: "#FF6B9A", lessons: [
            Lesson(id: "u1l1", title: "-at words", icon: "🐱", words: [
                w("cat", ["c","a","t"], picture: "🐱"), w("hat", ["h","a","t"], picture: "🎩"),
                w("bat", ["b","a","t"], picture: "🦇"), w("mat", ["m","a","t"]),
                w("sat", ["s","a","t"]), w("rat", ["r","a","t"], picture: "🐀")
            ]),
            Lesson(id: "u1l2", title: "-an & -ap", icon: "🧢", words: [
                w("can", ["c","a","n"]), w("man", ["m","a","n"]), w("pan", ["p","a","n"], picture: "🍳"),
                w("ran", ["r","a","n"]), w("cap", ["c","a","p"], picture: "🧢"),
                w("map", ["m","a","p"], picture: "🗺️"), w("nap", ["n","a","p"]), w("tap", ["t","a","p"])
            ]),
            Lesson(id: "u1l3", title: "-ad, -ag, -am", icon: "🛍️", words: [
                w("bad", ["b","a","d"]), w("sad", ["s","a","d"], picture: "😢"), w("dad", ["d","a","d"]),
                w("bag", ["b","a","g"], picture: "🛍️"), w("tag", ["t","a","g"], picture: "🏷️"),
                w("ham", ["h","a","m"], picture: "🍖"), w("jam", ["j","a","m"], picture: "🍓")
            ])
        ]),

        // MARK: Unit 2 — short i
        Unit(id: "u2", title: "Short i", colorA: "#67C8FF", colorB: "#5B8CFF", lessons: [
            Lesson(id: "u2l1", title: "-it & -ig", icon: "🐷", words: [
                w("sit", ["s","i","t"]), w("hit", ["h","i","t"]), w("bit", ["b","i","t"]),
                w("big", ["b","i","g"]), w("pig", ["p","i","g"], picture: "🐷"),
                w("dig", ["d","i","g"], picture: "🕳️"), w("wig", ["w","i","g"])
            ]),
            Lesson(id: "u2l2", title: "-in & -ip", icon: "📌", words: [
                w("pin", ["p","i","n"], picture: "📌"), w("win", ["w","i","n"], picture: "🏆"),
                w("fin", ["f","i","n"], picture: "🐟"), w("lip", ["l","i","p"], picture: "👄"),
                w("tip", ["t","i","p"]), w("zip", ["z","i","p"], picture: "🤐"), w("rip", ["r","i","p"])
            ]),
            Lesson(id: "u2l3", title: "-id & -ix", icon: "🧒", words: [
                w("did", ["d","i","d"]), w("lid", ["l","i","d"]), w("kid", ["k","i","d"], picture: "🧒"),
                w("hid", ["h","i","d"]), w("six", ["s","i","x"], picture: "6️⃣"), w("mix", ["m","i","x"])
            ]),
            Lesson(id: "u2l4", title: "More short i", icon: "🧰", words: [
                w("fit", ["f","i","t"]), w("fig", ["f","i","g"], picture: "🍈"),
                w("bin", ["b","i","n"], picture: "🗑️"), w("fix", ["f","i","x"], picture: "🔧"),
                w("kit", ["k","i","t"], picture: "🧰"), w("lit", ["l","i","t"], picture: "🕯️")
            ])
        ]),

        // MARK: Unit 3 — short o
        Unit(id: "u3", title: "Short o", colorA: "#5BD16B", colorB: "#2FB37E", lessons: [
            Lesson(id: "u3l1", title: "-ot & -og", icon: "🐶", words: [
                w("hot", ["h","o","t"], picture: "🔥"), w("pot", ["p","o","t"], picture: "🍲"),
                w("dot", ["d","o","t"]), w("got", ["g","o","t"]), w("dog", ["d","o","g"], picture: "🐶"),
                w("log", ["l","o","g"], picture: "🪵"), w("fog", ["f","o","g"], picture: "🌫️")
            ]),
            Lesson(id: "u3l2", title: "-op & -ox", icon: "🦊", words: [
                w("top", ["t","o","p"]), w("mop", ["m","o","p"]), w("hop", ["h","o","p"], picture: "🐇"),
                w("pop", ["p","o","p"], picture: "🎈"), w("box", ["b","o","x"], picture: "📦"),
                w("fox", ["f","o","x"], picture: "🦊")
            ]),
            Lesson(id: "u3l3", title: "-ob & -od", icon: "🌽", words: [
                w("job", ["j","o","b"]), w("rob", ["r","o","b"]), w("cob", ["c","o","b"], picture: "🌽"),
                w("nod", ["n","o","d"]), w("rod", ["r","o","d"]), w("cod", ["c","o","d"], picture: "🐟")
            ]),
            Lesson(id: "u3l4", title: "More short o", icon: "🛏️", words: [
                w("cot", ["c","o","t"], picture: "🛏️"), w("hog", ["h","o","g"], picture: "🐗"),
                w("jog", ["j","o","g"], picture: "🏃"), w("mom", ["m","o","m"], picture: "👩"),
                w("pod", ["p","o","d"], picture: "🫛"), w("lot", ["l","o","t"])
            ])
        ]),

        // MARK: Unit 4 — short u
        Unit(id: "u4", title: "Short u", colorA: "#FFCD3C", colorB: "#FF9A3C", lessons: [
            Lesson(id: "u4l1", title: "-ug & -un", icon: "🐞", words: [
                w("bug", ["b","u","g"], picture: "🐞"), w("rug", ["r","u","g"]),
                w("hug", ["h","u","g"], picture: "🤗"), w("mug", ["m","u","g"], picture: "☕"),
                w("sun", ["s","u","n"], picture: "☀️"), w("run", ["r","u","n"], picture: "🏃"),
                w("fun", ["f","u","n"], picture: "🎉"), w("bun", ["b","u","n"], picture: "🥯")
            ]),
            Lesson(id: "u4l2", title: "-ut & -up", icon: "🥜", words: [
                w("cut", ["c","u","t"], picture: "✂️"), w("nut", ["n","u","t"], picture: "🥜"),
                w("hut", ["h","u","t"], picture: "🛖"), w("but", ["b","u","t"]),
                w("cup", ["c","u","p"], picture: "🥤"), w("pup", ["p","u","p"], picture: "🐶")
            ]),
            Lesson(id: "u4l3", title: "-ub & bus", icon: "🚌", words: [
                w("tub", ["t","u","b"], picture: "🛁"), w("cub", ["c","u","b"], picture: "🐻"),
                w("rub", ["r","u","b"]), w("bus", ["b","u","s"], picture: "🚌"),
                w("us", ["u","s"]), w("mud", ["m","u","d"])
            ]),
            Lesson(id: "u4l4", title: "More short u", icon: "🫙", words: [
                w("gum", ["g","u","m"]), w("bud", ["b","u","d"], picture: "🌷"),
                w("jug", ["j","u","g"], picture: "🫙"), w("sub", ["s","u","b"], picture: "🥪"),
                w("tug", ["t","u","g"]), w("dug", ["d","u","g"])
            ])
        ]),

        // MARK: Unit 5 — short e + first sentences
        Unit(id: "u5", title: "Short e & Reading", colorA: "#A78BFA", colorB: "#7C5CFF", lessons: [
            Lesson(id: "u5l1", title: "-ed & -en", icon: "🛏️", words: [
                w("bed", ["b","e","d"], picture: "🛏️"), w("red", ["r","e","d"], picture: "🟥"),
                w("fed", ["f","e","d"]), w("hen", ["h","e","n"], picture: "🐔"),
                w("pen", ["p","e","n"], picture: "🖊️"), w("ten", ["t","e","n"], picture: "🔟"),
                w("men", ["m","e","n"])
            ]),
            Lesson(id: "u5l2", title: "-et & -eg", icon: "🚀", words: [
                w("net", ["n","e","t"], picture: "🥅"), w("jet", ["j","e","t"], picture: "✈️"),
                w("wet", ["w","e","t"], picture: "💧"), w("pet", ["p","e","t"], picture: "🐾"),
                w("get", ["g","e","t"]), w("leg", ["l","e","g"], picture: "🦵"), w("egg", ["e","gg"], picture: "🥚")
            ]),
            Lesson(id: "u5l3", title: "First Sentences!", icon: "📖", words: [
                w("the", ["th:ð","e:ə"]), w("is", ["i","s:z"]), w("a", ["a:ə"])
            ], sentences: [
                ["the","cat","sat"],
                ["the","pig","is","big"],
                ["a","red","hen"],
                ["the","sun","is","hot"],
                ["the","dog","ran"]
            ])
        ]),

        // MARK: Unit 6 — digraphs
        Unit(id: "u6", title: "Two Letters, One Sound", colorA: "#FF7E6B", colorB: "#FF4F8B", lessons: [
            Lesson(id: "u6l1", title: "sh", icon: "🐟", words: [
                w("ship", ["sh","i","p"], picture: "🚢"), w("shop", ["sh","o","p"], picture: "🏪"),
                w("fish", ["f","i","sh"], picture: "🐟"), w("dish", ["d","i","sh"], picture: "🍽️"),
                w("wish", ["w","i","sh"], picture: "⭐"), w("cash", ["c","a","sh"], picture: "💵")
            ]),
            Lesson(id: "u6l2", title: "ch", icon: "🍟", words: [
                w("chip", ["ch","i","p"], picture: "🍟"), w("chop", ["ch","o","p"]),
                w("chin", ["ch","i","n"]), w("chat", ["ch","a","t"], picture: "💬"),
                w("rich", ["r","i","ch"], picture: "💰"), w("much", ["m","u","ch"])
            ]),
            Lesson(id: "u6l3", title: "th", icon: "👍", words: [
                w("thin", ["th","i","n"]), w("bath", ["b","a","th"], picture: "🛁"),
                w("with", ["w","i","th"]), w("this", ["th:ð","i","s"], picture: "👉"),
                w("that", ["th:ð","a","t"]), w("then", ["th:ð","e","n"])
            ]),
            Lesson(id: "u6l4", title: "ck & ng", icon: "🦆", words: [
                w("duck", ["d","u","ck"], picture: "🦆"), w("sock", ["s","o","ck"], picture: "🧦"),
                w("rock", ["r","o","ck"], picture: "🪨"), w("ring", ["r","i","ng"], picture: "💍"),
                w("king", ["k","i","ng"], picture: "👑"), w("song", ["s","o","ng"], picture: "🎵")
            ], sentences: [
                ["the","fish","is","in","the","dish"],
                ["this","is","my","ship"],
                ["the","king","has","a","ring"]
            ])
        ]),

        // MARK: Unit 7 — blends
        Unit(id: "u7", title: "Blends", colorA: "#2FB37E", colorB: "#1E9E9E", lessons: [
            Lesson(id: "u7l1", title: "l-blends", icon: "🚩", words: [
                w("flag", ["f","l","a","g"], picture: "🚩"), w("clap", ["c","l","a","p"], picture: "👏"),
                w("plan", ["p","l","a","n"]), w("glad", ["g","l","a","d"], picture: "😄"),
                w("slip", ["s","l","i","p"]), w("clip", ["c","l","i","p"], picture: "📎")
            ]),
            Lesson(id: "u7l2", title: "r-blends", icon: "🐸", words: [
                w("frog", ["f","r","o","g"], picture: "🐸"), w("drum", ["d","r","u","m"], picture: "🥁"),
                w("trip", ["t","r","i","p"]), w("grab", ["g","r","a","b"]),
                w("crab", ["c","r","a","b"], picture: "🦀"), w("brick", ["b","r","i","ck"], picture: "🧱")
            ]),
            Lesson(id: "u7l3", title: "s-blends", icon: "🏊", words: [
                w("stop", ["s","t","o","p"], picture: "🛑"), w("spin", ["s","p","i","n"], picture: "🌀"),
                w("swim", ["s","w","i","m"], picture: "🏊"), w("snap", ["s","n","a","p"]),
                w("skip", ["s","k","i","p"]), w("sled", ["s","l","e","d"], picture: "🛷")
            ]),
            Lesson(id: "u7l4", title: "End blends", icon: "🦘", words: [
                w("jump", ["j","u","m","p"], picture: "🦘"), w("hand", ["h","a","n","d"], picture: "✋"),
                w("tent", ["t","e","n","t"], picture: "⛺"), w("milk", ["m","i","l","k"], picture: "🥛"),
                w("fast", ["f","a","s","t"], picture: "💨"), w("nest", ["n","e","s","t"], picture: "🪺")
            ], sentences: [
                ["the","frog","can","jump"],
                ["stop","the","fast","bus"],
                ["a","crab","and","a","fish"]
            ])
        ]),

        // MARK: Unit 8 — magic e
        Unit(id: "u8", title: "Magic e", colorA: "#FF6B9A", colorB: "#B14CFF", lessons: [
            Lesson(id: "u8l1", title: "a_e", icon: "🎂", words: [
                w("cake", ["c","a:eɪ","k","e:"], picture: "🎂"), w("name", ["n","a:eɪ","m","e:"]),
                w("game", ["g","a:eɪ","m","e:"], picture: "🎮"), w("gate", ["g","a:eɪ","t","e:"], picture: "🚪"),
                w("cave", ["c","a:eɪ","v","e:"], picture: "🕳️"), w("late", ["l","a:eɪ","t","e:"], picture: "⏰")
            ]),
            Lesson(id: "u8l2", title: "i_e", icon: "🚲", words: [
                w("bike", ["b","i:aɪ","k","e:"], picture: "🚲"), w("time", ["t","i:aɪ","m","e:"], picture: "⏱️"),
                w("ride", ["r","i:aɪ","d","e:"]), w("kite", ["k","i:aɪ","t","e:"], picture: "🪁"),
                w("five", ["f","i:aɪ","v","e:"], picture: "5️⃣"), w("line", ["l","i:aɪ","n","e:"], picture: "➖")
            ]),
            Lesson(id: "u8l3", title: "o_e & u_e", icon: "🏠", words: [
                w("home", ["h","o:oʊ","m","e:"], picture: "🏠"), w("bone", ["b","o:oʊ","n","e:"], picture: "🦴"),
                w("rope", ["r","o:oʊ","p","e:"], picture: "🪢"), w("nose", ["n","o:oʊ","s:z","e:"], picture: "👃"),
                w("cute", ["c","u:juː","t","e:"], picture: "🥰"), w("tube", ["t","u:uː","b","e:"])
            ], sentences: [
                ["i","like","my","bike"],
                ["the","cake","is","mine"],
                ["i","can","ride","home"]
            ])
        ]),

        // MARK: Unit 9 — vowel teams
        Unit(id: "u9", title: "Vowel Teams", colorA: "#67C8FF", colorB: "#5BD16B", lessons: [
            Lesson(id: "u9l1", title: "ai & ay", icon: "🌧️", words: [
                w("rain", ["r","ai","n"], picture: "🌧️"), w("wait", ["w","ai","t"]),
                w("pain", ["p","ai","n"]), w("day", ["d","ay"], picture: "☀️"),
                w("play", ["p","l","ay"], picture: "🛝"), w("say", ["s","ay"], picture: "💬")
            ]),
            Lesson(id: "u9l2", title: "ee & ea", icon: "🌳", words: [
                w("see", ["s","ee"], picture: "👀"), w("tree", ["t","r","ee"], picture: "🌳"),
                w("feet", ["f","ee","t"], picture: "🦶"), w("green", ["g","r","ee","n"], picture: "🟢"),
                w("eat", ["ea","t"], picture: "🍽️"), w("sea", ["s","ea"], picture: "🌊")
            ]),
            Lesson(id: "u9l3", title: "oa & ow", icon: "⛵", words: [
                w("boat", ["b","oa","t"], picture: "⛵"), w("coat", ["c","oa","t"], picture: "🧥"),
                w("road", ["r","oa","d"], picture: "🛣️"), w("snow", ["s","n","ow"], picture: "❄️"),
                w("grow", ["g","r","ow"], picture: "🌱"), w("slow", ["s","l","ow"], picture: "🐌")
            ]),
            Lesson(id: "u9l4", title: "igh & oo", icon: "🌙", words: [
                w("light", ["l","igh","t"], picture: "💡"), w("night", ["n","igh","t"], picture: "🌙"),
                w("high", ["h","igh"], picture: "⬆️"), w("moon", ["m","oo","n"], picture: "🌕"),
                w("zoo", ["z","oo"], picture: "🦁"), w("book", ["b","oo:ʊ","k"], picture: "📚")
            ], sentences: [
                ["i","see","a","green","tree"],
                ["the","boat","is","slow"],
                ["look","at","the","moon"]
            ])
        ]),

        // MARK: Unit 10 — r-controlled
        Unit(id: "u10", title: "Bossy r", colorA: "#FF9A3C", colorB: "#FF5E5E", lessons: [
            Lesson(id: "u10l1", title: "ar", icon: "🚗", words: [
                w("car", ["c","ar"], picture: "🚗"), w("star", ["s","t","ar"], picture: "⭐"),
                w("far", ["f","ar"]), w("arm", ["ar","m"], picture: "💪"),
                w("card", ["c","ar","d"], picture: "🃏"), w("park", ["p","ar","k"], picture: "🏞️")
            ]),
            Lesson(id: "u10l2", title: "or", icon: "🌽", words: [
                w("for", ["f","or"]), w("corn", ["c","or","n"], picture: "🌽"),
                w("fork", ["f","or","k"], picture: "🍴"), w("born", ["b","or","n"], picture: "👶"),
                w("storm", ["s","t","or","m"], picture: "⛈️"), w("horn", ["h","or","n"], picture: "📯")
            ]),
            Lesson(id: "u10l3", title: "er, ir, ur", icon: "🐦", words: [
                w("her", ["h","er"]), w("bird", ["b","ir","d"], picture: "🐦"),
                w("girl", ["g","ir","l"], picture: "👧"), w("turn", ["t","ur","n"], picture: "↩️"),
                w("hurt", ["h","ur","t"], picture: "🤕"), w("fur", ["f","ur"], picture: "🧶")
            ], sentences: [
                ["the","car","is","far"],
                ["a","bird","and","a","girl"],
                ["the","corn","is","for","her"]
            ])
        ]),

        // MARK: Unit 11 — diphthongs
        Unit(id: "u11", title: "Sound Surprises", colorA: "#7C5CFF", colorB: "#2FB3C9", lessons: [
            Lesson(id: "u11l1", title: "ou & ow", icon: "🐮", words: [
                w("out", ["ou","t"]), w("cloud", ["c","l","ou","d"], picture: "☁️"),
                w("loud", ["l","ou","d"], picture: "📢"), w("cow", ["c","ow:aʊ"], picture: "🐮"),
                w("down", ["d","ow:aʊ","n"], picture: "⬇️"), w("owl", ["ow:aʊ","l"], picture: "🦉")
            ]),
            Lesson(id: "u11l2", title: "oi & oy", icon: "🧸", words: [
                w("oil", ["oi","l"], picture: "🛢️"), w("coin", ["c","oi","n"], picture: "🪙"),
                w("join", ["j","oi","n"], picture: "🤝"), w("boy", ["b","oy"], picture: "👦"),
                w("toy", ["t","oy"], picture: "🧸"), w("joy", ["j","oy"], picture: "😊")
            ]),
            Lesson(id: "u11l3", title: "aw & au", icon: "🐾", words: [
                w("saw", ["s","aw"], picture: "🪚"), w("paw", ["p","aw"], picture: "🐾"),
                w("draw", ["d","r","aw"], picture: "✏️"), w("claw", ["c","l","aw"], picture: "🦞"),
                w("yawn", ["y","aw","n"], picture: "🥱"), w("lawn", ["l","aw","n"], picture: "🌿")
            ], sentences: [
                ["the","boy","has","a","toy"],
                ["i","see","an","owl"],
                ["the","cow","is","down"]
            ])
        ]),

        // MARK: Unit 12 — original decodable stories
        Unit(id: "u12", title: "Story Time", colorA: "#FF6B9A", colorB: "#FFCD3C", lessons: [
            Lesson(id: "u12l1", title: "The Big Hat", icon: "🎩", sentences: [
                ["the","cat","has","a","big","hat"],
                ["the","hat","is","red"],
                ["a","rat","sat","on","the","hat"],
                ["the","cat","ran","at","the","rat"],
                ["the","rat","ran","and","ran"]
            ]),
            Lesson(id: "u12l2", title: "Fish and Frog", icon: "🐸", sentences: [
                ["a","fish","and","a","frog"],
                ["the","frog","can","hop"],
                ["the","fish","can","not","hop"],
                ["the","fish","can","swim"],
                ["the","frog","can","swim","too"]
            ]),
            Lesson(id: "u12l3", title: "My Red Bike", icon: "🚲", sentences: [
                ["i","have","a","red","bike"],
                ["i","ride","my","bike","fast"],
                ["i","go","up","the","hill"],
                ["i","go","down","the","hill"],
                ["my","bike","is","the","best"]
            ]),
            Lesson(id: "u12l4", title: "The Moon", icon: "🌙", sentences: [
                ["it","is","night"],
                ["i","see","the","moon"],
                ["the","moon","is","big","and","bright"],
                ["an","owl","is","out"],
                ["the","owl","can","see","the","moon"]
            ]),
            Lesson(id: "u12l5", title: "The Sleepy Pup", icon: "🐶", sentences: [
                ["my","pup","is","on","the","rug"],
                ["the","pup","had","a","fun","day"],
                ["the","pup","can","not","run"],
                ["i","see","the","pup","yawn"],
                ["my","pup","is","in","bed"],
                ["sleep","tight","my","pup"]
            ]),
            Lesson(id: "u12l6", title: "Duck at the Lake", icon: "🦆", sentences: [
                ["a","duck","is","at","the","lake"],
                ["the","duck","can","swim","fast"],
                ["the","duck","can","see","a","fish"],
                ["the","fish","will","not","play"],
                ["the","duck","will","nap","on","a","log"],
                ["the","lake","is","calm","and","still"]
            ]),
            Lesson(id: "u12l7", title: "Bug and the Bee", icon: "🐝", sentences: [
                ["a","bug","sat","on","a","leaf"],
                ["a","bee","can","see","the","bug"],
                ["the","bee","will","not","sting"],
                ["the","bee","and","the","bug","play"],
                ["we","like","to","run","and","hop"],
                ["it","is","fun","to","have","a","pal"]
            ]),
            Lesson(id: "u12l8", title: "Pup and the Hat", icon: "🐶", sentences: [
                ["my","pup","has","a","red","hat"],
                ["the","hat","is","big"],
                ["the","pup","can","sit","on","it"],
                ["a","cat","can","see","the","pup"],
                ["the","cat","and","the","pup","run"],
                ["it","is","fun","to","run"],
                ["we","like","the","big","red","hat"]
            ]),
            Lesson(id: "u12l9", title: "The Bug on the Log", icon: "🪵", sentences: [
                ["a","bug","is","on","a","log"],
                ["the","bug","is","red"],
                ["a","big","bug","can","not","see"],
                ["i","can","see","the","bug"],
                ["the","bug","will","go","up"],
                ["the","bug","can","go","up","and","up"],
                ["we","like","the","red","bug"]
            ])
        ])
    ]
}
