import Foundation

/// British English (RP) grapheme → phoneme table + decodable word builder.
///
/// Every grapheme a word is segmented with MUST be a key in `map` (the
/// decodability invariant: graphemes join to the text and each is known). RP is a
/// shallow-enough orthography for the flat `map` lookup the transparent packs use.
///
/// NON-RHOTIC: the r-controlled teams (ar, or, ur, ir, air, ear, ure) map to a
/// PURE RP vowel — **no /r/ is ever sounded** (car → /kɑː/, hair → /heə/).
/// `o = /ɒ/` (British LOT). A handful of graphemes are genuinely two-valued in
/// RP (ow = /əʊ/ snow vs /aʊ/ cow; oo = /uː/ moon vs /ʊ/ book): the table holds
/// the PRIMARY value and the rarer reading is passed inline as "ow:aʊ" / "oo:ʊ"
/// in the word builder, exactly like the English pack's magic-e long vowels.
enum EnglishUKPhonics: PhonicsPack {
    static let map: [String: String] = {
        var m: [String: String] = [:]
        for L in EnglishUKLand.letters { m[L.letter] = L.ipa }
        // q is taught only inside the qu digraph, but keep it a known key.
        m["q"] = "k"
        // CONSONANT DIGRAPHS (Phase 3)
        m["ch"] = "tʃ"
        m["sh"] = "ʃ"
        m["th"] = "θ"   // voiceless th (thin); voiced (this, that) passed inline "th:ð"
        m["ng"] = "ŋ"
        m["qu"] = "kw"
        m["ck"] = "k"
        // DOUBLED CONSONANTS → single sound
        m["ss"] = "s"
        m["ll"] = "l"
        m["ff"] = "f"
        m["zz"] = "z"
        // LONG-VOWEL VOWEL TEAMS (Phase 3/5)
        m["ai"] = "eɪ"
        m["ay"] = "eɪ"
        m["ee"] = "iː"
        m["ea"] = "iː"
        m["igh"] = "aɪ"
        m["ie"] = "aɪ"
        m["oa"] = "əʊ"
        m["ow"] = "əʊ"  // snow (primary); cow-type passed inline as "ow:aʊ"
        m["oo"] = "uː"  // moon (primary); book-type passed inline as "oo:ʊ"
        // R-CONTROLLED (NON-RHOTIC RP — pure vowel, NO /r/ sounded)
        m["ar"] = "ɑː"
        m["or"] = "ɔː"
        m["ur"] = "ɜː"
        m["ir"] = "ɜː"
        m["air"] = "eə"
        m["ear"] = "ɪə"
        m["ure"] = "ʊə"
        m["er"] = "ə"   // final unstressed schwa (ladder, garden)
        m["le"] = "əl"  // final syllabic l (little, apple) — kept for later use
        // DIPHTHONGS
        m["ou"] = "aʊ"
        m["oi"] = "ɔɪ"
        m["oy"] = "ɔɪ"
        return m
    }()

    /// Build a decodable word from chunk tokens (mirrors the Spanish template's
    /// `word()`), with the English-pack inline override "disp:ipa" so a grapheme
    /// can carry a non-primary RP reading while still displaying its real letters
    /// (e.g. "ow:aʊ" → tile shows "ow", sounds /aʊ/). The integrator wires the
    /// context engine; no resolver logic lives here.
}

extension EnglishUKLand {
    static let wordUnits: [Unit] = {
        func w(_ t: String, _ ls: [String], _ p: String) -> PWord { EnglishUKPhonics.word(t, ls, p) }

        // UNIT 1 — Phase 2 CVC: satpin words
        let u1 = Unit(id: "en-GB_w1", title: "First Words", colorA: "#5BD16B", colorB: "#67C8FF", lessons: [
            Lesson(id: "en-GB_w1_1", title: "sat & pat", icon: "🐱",
                   words: [w("sat", ["s","a","t"], "🪑"),
                           w("pat", ["p","a","t"], "👋"),
                           w("tap", ["t","a","p"], "🚰")]),
            Lesson(id: "en-GB_w1_2", title: "pin & nip", icon: "📌",
                   words: [w("pin", ["p","i","n"], "📌"),
                           w("nip", ["n","i","p"], "🦀"),
                           w("sit", ["s","i","t"], "🪑")]),
            Lesson(id: "en-GB_w1_3", title: "pan & map", icon: "🍳",
                   words: [w("pan", ["p","a","n"], "🍳"),
                           w("tan", ["t","a","n"], "🟤"),
                           w("map", ["m","a","p"], "🗺️"),
                           w("tip", ["t","i","p"], "💡")]),
        ])

        // UNIT 2 — Phase 2 more CVC (m d g o c k e u r h b f l + ck)
        let u2 = Unit(id: "en-GB_w2", title: "Short Words", colorA: "#FFB14E", colorB: "#FF6B9A", lessons: [
            Lesson(id: "en-GB_w2_1", title: "dog & cat", icon: "🐶",
                   words: [w("dog", ["d","o","g"], "🐶"),
                           w("got", ["g","o","t"], "🤲"),
                           w("cot", ["c","o","t"], "🛏️"),
                           w("cat", ["c","a","t"], "🐱")]),
            Lesson(id: "en-GB_w2_2", title: "pen & bed", icon: "🖊️",
                   words: [w("pen", ["p","e","n"], "🖊️"),
                           w("ten", ["t","e","n"], "🔟"),
                           w("net", ["n","e","t"], "🥅"),
                           w("bed", ["b","e","d"], "🛏️"),
                           w("peg", ["p","e","g"], "📎")]),
            Lesson(id: "en-GB_w2_3", title: "bus & hat", icon: "🚌",
                   words: [w("bus", ["b","u","s"], "🚌"),
                           w("bun", ["b","u","n"], "🥯"),
                           w("run", ["r","u","n"], "🏃"),
                           w("rug", ["r","u","g"], "🧶"),
                           w("hut", ["h","u","t"], "🛖")]),
            Lesson(id: "en-GB_w2_4", title: "hen & big", icon: "🐔",
                   words: [w("hen", ["h","e","n"], "🐔"),
                           w("hat", ["h","a","t"], "🎩"),
                           w("hot", ["h","o","t"], "🔥"),
                           w("bag", ["b","a","g"], "👜"),
                           w("big", ["b","i","g"], "🐘")]),
            Lesson(id: "en-GB_w2_5", title: "fun & leg", icon: "🦵",
                   words: [w("fan", ["f","a","n"], "🪭"),
                           w("fun", ["f","u","n"], "🎉"),
                           w("fit", ["f","i","t"], "💪"),
                           w("log", ["l","o","g"], "🪵"),
                           w("leg", ["l","e","g"], "🦵"),
                           w("lip", ["l","i","p"], "👄")]),
            Lesson(id: "en-GB_w2_6", title: "sock (ck)", icon: "🧦",
                   words: [w("sock", ["s","o","ck"], "🧦"),
                           w("kick", ["k","i","ck"], "🦵"),
                           w("duck", ["d","u","ck"], "🦆"),
                           w("rock", ["r","o","ck"], "🪨")]),
        ])

        // UNIT 3 — consonant digraphs ch / sh / th / ng
        let u3 = Unit(id: "en-GB_w3", title: "Two Letters, One Sound", colorA: "#9B6BFF", colorB: "#67C8FF", lessons: [
            Lesson(id: "en-GB_w3_1", title: "ch & sh", icon: "🚢",
                   words: [w("chip", ["ch","i","p"], "🍟"),
                           w("chop", ["ch","o","p"], "🪓"),
                           w("shop", ["sh","o","p"], "🏪"),
                           w("ship", ["sh","i","p"], "🚢")]),
            Lesson(id: "en-GB_w3_2", title: "sh & th", icon: "🐟",
                   words: [w("fish", ["f","i","sh"], "🐟"),
                           w("this", ["th:ð","i","s"], "👉"),
                           w("that", ["th:ð","a","t"], "👈"),
                           w("thin", ["th","i","n"], "📏")]),
            Lesson(id: "en-GB_w3_3", title: "ng", icon: "💍",
                   words: [w("ring", ["r","i","ng"], "💍"),
                           w("sing", ["s","i","ng"], "🎤"),
                           w("bang", ["b","a","ng"], "💥"),
                           w("king", ["k","i","ng"], "👑")]),
        ])

        // UNIT 4 — long-vowel teams ai / ee / igh / oa / oo
        let u4 = Unit(id: "en-GB_w4", title: "Long Sounds", colorA: "#FF6B9A", colorB: "#FFB14E", lessons: [
            Lesson(id: "en-GB_w4_1", title: "ai", icon: "🌧️",
                   words: [w("rain", ["r","ai","n"], "🌧️"),
                           w("train", ["t","r","ai","n"], "🚂"),
                           w("pain", ["p","ai","n"], "🤕")]),
            Lesson(id: "en-GB_w4_2", title: "ee", icon: "🌳",
                   words: [w("see", ["s","ee"], "👀"),
                           w("feet", ["f","ee","t"], "🦶"),
                           w("tree", ["t","r","ee"], "🌳")]),
            Lesson(id: "en-GB_w4_3", title: "igh", icon: "🌙",
                   words: [w("light", ["l","igh","t"], "💡"),
                           w("night", ["n","igh","t"], "🌙"),
                           w("high", ["h","igh"], "⬆️")]),
            Lesson(id: "en-GB_w4_4", title: "oa", icon: "⛵",
                   words: [w("boat", ["b","oa","t"], "⛵"),
                           w("goat", ["g","oa","t"], "🐐"),
                           w("coat", ["c","oa","t"], "🧥")]),
            Lesson(id: "en-GB_w4_5", title: "oo", icon: "🌕",
                   words: [w("moon", ["m","oo","n"], "🌕"),
                           w("food", ["f","oo","d"], "🍽️"),
                           w("zoo", ["z","oo"], "🦁")]),
        ])

        // UNIT 5 — r-controlled + diphthongs (NON-RHOTIC RP)
        let u5 = Unit(id: "en-GB_w5", title: "Sound Surprises", colorA: "#67C8FF", colorB: "#5BD16B", lessons: [
            Lesson(id: "en-GB_w5_1", title: "ar", icon: "🚗",
                   words: [w("car", ["c","ar"], "🚗"),
                           w("star", ["s","t","ar"], "⭐"),
                           w("arm", ["ar","m"], "💪")]),
            Lesson(id: "en-GB_w5_2", title: "or & ur", icon: "🍴",
                   words: [w("fork", ["f","or","k"], "🍴"),
                           w("corn", ["c","or","n"], "🌽"),
                           w("turn", ["t","ur","n"], "↩️"),
                           w("burn", ["b","ur","n"], "🔥")]),
            Lesson(id: "en-GB_w5_3", title: "ow & oi", icon: "🐮",
                   words: [w("cow", ["c","ow:aʊ"], "🐮"),
                           w("owl", ["ow:aʊ","l"], "🦉"),
                           w("coin", ["c","oi","n"], "🪙"),
                           w("boil", ["b","oi","l"], "🫧")]),
            Lesson(id: "en-GB_w5_4", title: "air & ear", icon: "🪑",
                   words: [w("hair", ["h","air"], "💇"),
                           w("chair", ["ch","air"], "🪑"),
                           w("pair", ["p","air"], "👫"),
                           w("dear", ["d","ear"], "💝"),
                           w("ear", ["ear"], "👂")]),
        ])

        // UNIT 6 — longer CVCC & two-syllable words
        let u6 = Unit(id: "en-GB_w6", title: "Longer Words", colorA: "#FFCD3C", colorB: "#FF6B9A", lessons: [
            Lesson(id: "en-GB_w6_1", title: "end blends", icon: "✋",
                   words: [w("hand", ["h","a","n","d"], "✋"),
                           w("lamp", ["l","a","m","p"], "💡"),
                           w("milk", ["m","i","l","k"], "🥛"),
                           w("jump", ["j","u","m","p"], "🦘")]),
            Lesson(id: "en-GB_w6_2", title: "two bits", icon: "🐰",
                   words: [w("rabbit", ["r","a","bb:b","i","t"], "🐰"),
                           w("kitten", ["k","i","tt:t","e","n"], "🐈"),
                           w("sunset", ["s","u","n","s","e","t"], "🌇")]),
            Lesson(id: "en-GB_w6_3", title: "er endings", icon: "🌷",
                   words: [w("garden", ["g","ar","d","e","n"], "🌷"),
                           w("ladder", ["l","a","dd:d","er"], "🪜"),
                           w("winter", ["w","i","n","t","er"], "❄️")]),
        ])

        // STORYBOOKS — decodable words + simple sight words
        // (the, a, is, to, and, I, go, no, he, she, we, me) ending with "the end!"
        let stories = Unit(id: "en-GB_stories", title: "Story Time", colorA: "#FF6B9A", colorB: "#FFCD3C", lessons: [
            Lesson(id: "en-GB_st_1", title: "The Cat", icon: "🐱",
                   sentences: [["the","cat"],
                               ["the","cat","sat"],
                               ["the","cat","is","big"],
                               ["the end!"]]),
            Lesson(id: "en-GB_st_2", title: "The Dog", icon: "🐶",
                   sentences: [["the","dog"],
                               ["the","dog","ran"],
                               ["the","dog","is","hot"],
                               ["the end!"]]),
            Lesson(id: "en-GB_st_3", title: "The Pig", icon: "🐷",
                   sentences: [["a","pig"],
                               ["the","pig","is","big"],
                               ["the","pig","sat","in","the","mud"],
                               ["the end!"]]),
            Lesson(id: "en-GB_st_4", title: "The Hen", icon: "🐔",
                   sentences: [["the","hen"],
                               ["the","hen","is","red"],
                               ["the","hen","sat","on","the","egg"],
                               ["the end!"]]),
            Lesson(id: "en-GB_st_5", title: "The Fish", icon: "🐟",
                   sentences: [["a","fish"],
                               ["the","fish","is","in","the","net"],
                               ["the","fish","can","swim"],
                               ["the end!"]]),
            Lesson(id: "en-GB_st_6", title: "The Bus", icon: "🚌",
                   sentences: [["the","bus"],
                               ["the","bus","is","red"],
                               ["we","go","on","the","bus"],
                               ["the end!"]]),
            Lesson(id: "en-GB_st_7", title: "The Ship", icon: "🚢",
                   sentences: [["a","ship"],
                               ["the","ship","is","big"],
                               ["the","ship","is","on","the","sea"],
                               ["the end!"]]),
            Lesson(id: "en-GB_st_8", title: "The Goat", icon: "🐐",
                   sentences: [["a","goat"],
                               ["the","goat","can","run"],
                               ["the","goat","has","a","coat"],
                               ["the end!"]]),
            Lesson(id: "en-GB_st_9", title: "The Moon", icon: "🌙",
                   sentences: [["it","is","night"],
                               ["i","see","the","moon"],
                               ["the","moon","is","big"],
                               ["the","owl","can","see","it","too"],
                               ["the end!"]]),
            Lesson(id: "en-GB_st_10", title: "The Car", icon: "🚗",
                   sentences: [["the","car"],
                               ["the","car","is","far"],
                               ["we","go","far","in","the","car"],
                               ["the end!"]]),
            Lesson(id: "en-GB_st_11", title: "The King", icon: "👑",
                   sentences: [["a","king"],
                               ["the","king","has","a","ring"],
                               ["the","king","can","sing"],
                               ["the end!"]]),
            Lesson(id: "en-GB_st_12", title: "The Rabbit", icon: "🐰",
                   sentences: [["a","rabbit"],
                               ["the","rabbit","can","jump"],
                               ["the","rabbit","sat","in","the","garden"],
                               ["the end!"]]),
            Lesson(id: "en-GB_st_13", title: "The Train", icon: "🚂",
                   sentences: [["the","train"],
                               ["the","train","is","fast"],
                               ["we","go","on","the","train"],
                               ["the train","is","in","the","rain"],
                               ["the end!"]]),
            Lesson(id: "en-GB_st_14", title: "The Cow and the Goat", icon: "🐮",
                   sentences: [["a","cow","and","a","goat"],
                               ["the","cow","is","big"],
                               ["the","goat","can","run"],
                               ["the","cow","and","the","goat","are","pals"],
                               ["the end!"]]),
        ])

        return [u1, u2, u3, u4, u5, u6, stories]
    }()
}