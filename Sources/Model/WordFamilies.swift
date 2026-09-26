import Foundation

/// Generated CVC word-family lessons — the engine for scaling the curriculum
/// toward Mentava's "thousands of small lessons." Each family is one rime (e.g.
/// "-at") expanded over the onsets that make REAL words, producing a focused
/// micro-lesson. Tokenisation is trivial+safe (each letter is its own grapheme),
/// so this stays correct no matter how many families we add — just append rows.
enum WordFamilies {

    private struct Family {
        let vowel: String      // a e i o u
        let final: String      // final consonant(s) of the rime
        let icon: String
        let onsets: [String]   // single-letter onsets that make a real word
        let pics: [String: String]
    }

    /// vowel → (unit title, color A/B)
    private static let vowelUnit: [String: (String, String, String)] = [
        "a": ("More Short a", "#FF9A6B", "#FF6B9A"),
        "e": ("More Short e", "#A78BFA", "#7C5CFF"),
        "i": ("More Short i", "#67C8FF", "#5B8CFF"),
        "o": ("More Short o", "#5BD16B", "#2FB37E"),
        "u": ("More Short u", "#FFCD3C", "#FF9A3C")
    ]
    private static let vowelOrder = ["a", "i", "o", "u", "e"]

    private static let families: [Family] = [
        // short a
        Family(vowel: "a", final: "t", icon: "🐱", onsets: ["c","h","b","m","s","r","f","p"],
               pics: ["cat":"🐱","hat":"🎩","bat":"🦇","rat":"🐀"]),
        Family(vowel: "a", final: "n", icon: "🍳", onsets: ["c","m","p","r","f","t","v","b"],
               pics: ["pan":"🍳","van":"🚐","fan":"🪭","man":"🧑"]),
        Family(vowel: "a", final: "p", icon: "🧢", onsets: ["c","m","n","t","l","g","s","r"],
               pics: ["cap":"🧢","map":"🗺️","tap":"🚰","lap":"🦵"]),
        Family(vowel: "a", final: "d", icon: "😢", onsets: ["b","d","h","m","s","p","l"],
               pics: ["sad":"😢","pad":"📝"]),
        Family(vowel: "a", final: "g", icon: "🛍️", onsets: ["b","t","r","w","n","s"],
               pics: ["bag":"🛍️","tag":"🏷️","rag":"🧻"]),
        // short i
        Family(vowel: "i", final: "t", icon: "🪑", onsets: ["s","h","b","f","k","l","p","w"],
               pics: ["sit":"🪑","kit":"🧰"]),
        Family(vowel: "i", final: "g", icon: "🐷", onsets: ["b","d","f","p","w","j","r"],
               pics: ["pig":"🐷","dig":"🕳️","wig":"💇","fig":"🍈"]),
        Family(vowel: "i", final: "n", icon: "📌", onsets: ["p","w","f","t","b","d"],
               pics: ["pin":"📌","fin":"🐟","win":"🏆","bin":"🗑️"]),
        Family(vowel: "i", final: "p", icon: "👄", onsets: ["l","t","z","r","d","h","n","s"],
               pics: ["lip":"👄","zip":"🤐","rip":"📄"]),
        Family(vowel: "i", final: "d", icon: "🧒", onsets: ["d","l","k","h","b","r"],
               pics: ["kid":"🧒","lid":"🍯"]),
        // short o
        Family(vowel: "o", final: "t", icon: "🔥", onsets: ["h","p","d","g","l","n","r","c"],
               pics: ["hot":"🔥","pot":"🍲","cot":"🛏️"]),
        Family(vowel: "o", final: "g", icon: "🐶", onsets: ["d","l","f","h","j","b"],
               pics: ["dog":"🐶","log":"🪵","fog":"🌫️","jog":"🏃"]),
        Family(vowel: "o", final: "p", icon: "🧹", onsets: ["t","m","h","p","c","s"],
               pics: ["mop":"🧹","hop":"🐇","top":"🔝","pop":"🎈"]),
        Family(vowel: "o", final: "x", icon: "🦊", onsets: ["b","f","p"],
               pics: ["box":"📦","fox":"🦊"]),
        Family(vowel: "o", final: "b", icon: "🌽", onsets: ["j","r","c","m","s","b"],
               pics: ["cob":"🌽","job":"💼"]),
        // short u
        Family(vowel: "u", final: "g", icon: "🐛", onsets: ["b","r","h","m","t","j","d","p"],
               pics: ["bug":"🐛","rug":"🧶","mug":"☕","hug":"🤗","jug":"🫙"]),
        Family(vowel: "u", final: "n", icon: "☀️", onsets: ["s","r","f","b","p"],
               pics: ["sun":"☀️","run":"🏃","bun":"🥯","fun":"🎉"]),
        Family(vowel: "u", final: "t", icon: "🥜", onsets: ["c","n","h","b","g"],
               pics: ["nut":"🥜","cut":"✂️","hut":"🛖"]),
        Family(vowel: "u", final: "p", icon: "🥤", onsets: ["c","p","s"],
               pics: ["cup":"🥤","pup":"🐶"]),
        Family(vowel: "u", final: "b", icon: "🛁", onsets: ["t","c","r","s","h"],
               pics: ["tub":"🛁","cub":"🐻","sub":"🥪"]),
        // short e
        Family(vowel: "e", final: "d", icon: "🛏️", onsets: ["b","r","f","l","w"],
               pics: ["bed":"🛏️","red":"🟥"]),
        Family(vowel: "e", final: "n", icon: "🐔", onsets: ["h","p","t","m","d"],
               pics: ["hen":"🐔","pen":"🖊️","ten":"🔟"]),
        Family(vowel: "e", final: "t", icon: "🥅", onsets: ["n","j","w","p","g","l","b","s"],
               pics: ["net":"🥅","jet":"✈️","wet":"💧","pet":"🐾"]),
        Family(vowel: "e", final: "g", icon: "🦵", onsets: ["l","b","p","k"],
               pics: ["leg":"🦵","peg":"📌"]),

        // more short a
        Family(vowel: "a", final: "m", icon: "🍓", onsets: ["h","j","r","y","d"],
               pics: ["ham":"🍖","jam":"🍓"]),
        Family(vowel: "a", final: "b", icon: "🦀", onsets: ["c","d","j","l","t","n"],
               pics: ["cab":"🚕","lab":"🧪"]),
        Family(vowel: "a", final: "ck", icon: "🎒", onsets: ["b","p","s","t","r","j"],
               pics: ["pack":"🎒","sack":"💰"]),
        Family(vowel: "a", final: "sh", icon: "💵", onsets: ["c","d","m","r","b"],
               pics: ["cash":"💵"]),
        Family(vowel: "a", final: "ll", icon: "⚽", onsets: ["b","c","f","h","t","w"],
               pics: ["ball":"⚽","wall":"🧱"]),
        // more short i
        Family(vowel: "i", final: "x", icon: "6️⃣", onsets: ["s","m","f"],
               pics: ["six":"6️⃣","fix":"🔧"]),
        Family(vowel: "i", final: "ck", icon: "🦵", onsets: ["k","l","p","s","t","w","n"],
               pics: ["kick":"🦵","sick":"🤒"]),
        Family(vowel: "i", final: "sh", icon: "🐟", onsets: ["d","f","w"],
               pics: ["dish":"🍽️","fish":"🐟","wish":"⭐"]),
        Family(vowel: "i", final: "ng", icon: "👑", onsets: ["k","r","s","w"],
               pics: ["king":"👑","ring":"💍","wing":"🪽"]),
        Family(vowel: "i", final: "ll", icon: "⛰️", onsets: ["b","f","h","p","w","m"],
               pics: ["hill":"⛰️","pill":"💊"]),
        // more short o
        Family(vowel: "o", final: "d", icon: "🐟", onsets: ["n","r","c","p"],
               pics: ["cod":"🐟","pod":"🫛"]),
        Family(vowel: "o", final: "ck", icon: "🧦", onsets: ["l","r","s","d","m"],
               pics: ["lock":"🔒","rock":"🪨","sock":"🧦"]),
        Family(vowel: "o", final: "ng", icon: "🎵", onsets: ["s","l","g"],
               pics: ["song":"🎵"]),
        // more short u
        Family(vowel: "u", final: "ck", icon: "🦆", onsets: ["d","l","p","s","t","b","m"],
               pics: ["duck":"🦆","truck":"🚚"]),
        Family(vowel: "u", final: "m", icon: "🍬", onsets: ["g","h","b","s","y","r"],
               pics: ["gum":"🍬","drum":"🥁"]),
        Family(vowel: "u", final: "sh", icon: "🌳", onsets: ["g","h","r","b"],
               pics: ["bush":"🌳"]),
        Family(vowel: "u", final: "ng", icon: "🫁", onsets: ["h","l","r","s"],
               pics: ["lung":"🫁"]),
        // more short e
        Family(vowel: "e", final: "ll", icon: "🔔", onsets: ["b","f","s","t","w","y"],
               pics: ["bell":"🔔","well":"🪣"]),
        Family(vowel: "e", final: "ck", icon: "🦒", onsets: ["d","n","p"],
               pics: ["neck":"🦒","deck":"🃏"])
    ]

    /// One bonus "More short X" unit per vowel, each holding that vowel's family
    /// micro-lessons. Appended after the core units so existing lesson ids/order
    /// are unchanged.
    static let units: [Unit] = vowelOrder.compactMap { v in
        guard let meta = vowelUnit[v] else { return nil }
        let fams = families.filter { $0.vowel == v }
        let lessons = fams.map { f -> Lesson in
            let words = f.onsets.map { o in
                Phonics.word(o + v + f.final, [o, v, f.final], picture: f.pics[o + v + f.final])
            }
            return Lesson(id: "fam_\(v)\(f.final)", title: "-\(v)\(f.final) words", icon: f.icon, words: words)
        }
        return Unit(id: "fam_\(v)", title: meta.0, colorA: meta.1, colorB: meta.2, lessons: lessons)
    }

    /// All generated family lesson ids, in order (for the e2e all-lessons list).
    static let lessonIDs: [String] = units.flatMap { $0.lessons.map { $0.id } }
}
