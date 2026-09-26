import Foundation

enum SpanishPhonics: PhonicsPack {
    static let map: [String: String] = {
        var m: [String: String] = [:]
        for L in SpanishLand.letters { m[L.letter] = L.ipa }
        for (a, b) in [("á","a"),("é","e"),("í","i"),("ó","o"),("ú","u"),("ü","u")] { m[a] = b }
        // DIGRAPHS
        m["ch"] = "tʃ"
        m["ll"] = "ʝ"
        m["rr"] = "r"
        m["qu"] = "k"
        m["gu"] = "g"
        // SOFT C before e/i (seseo → s)
        m["ce"] = "se"
        m["ci"] = "si"
        // SOFT G before e/i → x
        m["ge"] = "xe"
        m["gi"] = "xi"
        m["h"] = ""   // silent letter → empty string
        return m
    }()
}

extension SpanishLand {
    static let wordUnits: [Unit] = {
        func w(_ t: String, _ ls: [String], _ p: String) -> PWord { SpanishPhonics.word(t, ls, p) }

        // UNIT 1 — Two-sound words (vowel + consonant / open syllables)
        let u1 = Unit(id: "es_w1", title: "Primeras Palabras", colorA: "#5BD16B", colorB: "#67C8FF", lessons: [
            Lesson(id: "es_w1_1", title: "mamá", icon: "👩",
                   words: [w("mamá", ["m","a","m","á"], "👩"),
                           w("papá", ["p","a","p","á"], "👨")]),
            Lesson(id: "es_w1_2", title: "yo y tú", icon: "🙋",
                   words: [w("yo", ["y","o"], "🙋"),
                           w("ya", ["y","a"], "✅"),
                           w("su", ["s","u"], "👉")]),
            Lesson(id: "es_w1_3", title: "el sol", icon: "☀️",
                   words: [w("sol", ["s","o","l"], "☀️"),
                           w("sal", ["s","a","l"], "🧂"),
                           w("mes", ["m","e","s"], "📅")]),
        ])

        // UNIT 2 — CVC and simple CV words
        let u2 = Unit(id: "es_w2", title: "Palabras Cortas", colorA: "#FFB14E", colorB: "#FF6B9A", lessons: [
            Lesson(id: "es_w2_1", title: "pan", icon: "🍞",
                   words: [w("pan", ["p","a","n"], "🍞"),
                           w("pez", ["p","e","z"], "🐟"),
                           w("luz", ["l","u","z"], "💡")]),
            Lesson(id: "es_w2_2", title: "el mes", icon: "📅",
                   words: [w("tos", ["t","o","s"], "😷"),
                           w("ten", ["t","e","n"], "🤲"),
                           w("flan", ["f","l","a","n"], "🍮")]),
            Lesson(id: "es_w2_3", title: "el plan", icon: "📋",
                   words: [w("plan", ["p","l","a","n"], "📋"),
                           w("sed", ["s","e","d"], "🥤"),
                           w("sopa", ["s","o","p","a"], "🍲")]),
        ])

        // UNIT 3 — CVCV (two open syllables)
        let u3 = Unit(id: "es_w3", title: "Dos Sílabas", colorA: "#9B6BFF", colorB: "#67C8FF", lessons: [
            Lesson(id: "es_w3_1", title: "casa", icon: "🏠",
                   words: [w("casa", ["c","a","s","a"], "🏠"),
                           w("mesa", ["m","e","s","a"], "🪑"),
                           w("luna", ["l","u","n","a"], "🌙")]),
            Lesson(id: "es_w3_2", title: "gato", icon: "🐱",
                   words: [w("gato", ["g","a","t","o"], "🐱"),
                           w("pato", ["p","a","t","o"], "🦆"),
                           w("dedo", ["d","e","d","o"], "☝️")]),
            Lesson(id: "es_w3_3", title: "vaca", icon: "🐄",
                   words: [w("vaca", ["v","a","c","a"], "🐄"),
                           w("bota", ["b","o","t","a"], "👢"),
                           w("foca", ["f","o","c","a"], "🦭")]),
            Lesson(id: "es_w3_4", title: "pera", icon: "🍐",
                   words: [w("pera", ["p","e","r","a"], "🍐"),
                           w("oso", ["o","s","o"], "🐻"),
                           w("uva", ["u","v","a"], "🍇")]),
        ])

        // UNIT 4 — Three syllables
        let u4 = Unit(id: "es_w4", title: "Tres Sílabas", colorA: "#FF6B9A", colorB: "#FFB14E", lessons: [
            Lesson(id: "es_w4_1", title: "camisa", icon: "👕",
                   words: [w("camisa", ["c","a","m","i","s","a"], "👕"),
                           w("paloma", ["p","a","l","o","m","a"], "🕊️"),
                           w("pelota", ["p","e","l","o","t","a"], "⚽")]),
            Lesson(id: "es_w4_2", title: "tomate", icon: "🍅",
                   words: [w("tomate", ["t","o","m","a","t","e"], "🍅"),
                           w("zapato", ["z","a","p","a","t","o"], "👟"),
                           w("pirata", ["p","i","r","a","t","a"], "🏴‍☠️")]),
            Lesson(id: "es_w4_3", title: "música", icon: "🎵",
                   words: [w("música", ["m","ú","s","i","c","a"], "🎵"),
                           w("maleta", ["m","a","l","e","t","a"], "🧳"),
                           w("salida", ["s","a","l","i","d","a"], "🚪")]),
        ])

        // UNIT 5 — Digraphs (ch, ll, rr, qu, gu)
        let u5 = Unit(id: "es_w5", title: "Sonidos Especiales", colorA: "#67C8FF", colorB: "#5BD16B", lessons: [
            Lesson(id: "es_w5_1", title: "ch", icon: "🌮",
                   words: [w("leche", ["l","e","ch","e"], "🥛"),
                           w("coche", ["c","o","ch","e"], "🚗"),
                           w("ocho", ["o","ch","o"], "8️⃣")]),
            Lesson(id: "es_w5_2", title: "ll", icon: "🔑",
                   words: [w("llama", ["ll","a","m","a"], "🦙"),
                           w("silla", ["s","i","ll","a"], "🪑"),
                           w("pollo", ["p","o","ll","o"], "🐔")]),
            Lesson(id: "es_w5_3", title: "rr", icon: "🚜",
                   words: [w("perro", ["p","e","rr","o"], "🐶"),
                           w("torre", ["t","o","rr","e"], "🗼"),
                           w("carro", ["c","a","rr","o"], "🚙")]),
            Lesson(id: "es_w5_4", title: "qu y gu", icon: "🧀",
                   words: [w("queso", ["qu","e","s","o"], "🧀"),
                           w("paquete", ["p","a","qu","e","t","e"], "📦"),
                           w("guitarra", ["gu","i","t","a","rr","a"], "🎸")]),
        ])

        // UNIT 6 — Soft c (ce/ci) and soft g (ge/gi); ñ; harder words
        let u6 = Unit(id: "es_w6", title: "Palabras Largas", colorA: "#FFCD3C", colorB: "#FF6B9A", lessons: [
            Lesson(id: "es_w6_1", title: "ce y ci", icon: "🍒",
                   words: [w("cena", ["ce","n","a"], "🍽️"),
                           w("cielo", ["ci","e","l","o"], "☁️"),
                           w("cebolla", ["ce","b","o","ll","a"], "🧅")]),
            Lesson(id: "es_w6_2", title: "ge y gi", icon: "🌐",
                   words: [w("gente", ["ge","n","t","e"], "👥"),
                           w("gigante", ["gi","g","a","n","t","e"], "🦣"),
                           w("girasol", ["gi","r","a","s","o","l"], "🌻")]),
            Lesson(id: "es_w6_3", title: "la ñ", icon: "🧒",
                   words: [w("niño", ["n","i","ñ","o"], "👦"),
                           w("niña", ["n","i","ñ","a"], "👧"),
                           w("piña", ["p","i","ñ","a"], "🍍"),
                           w("araña", ["a","r","a","ñ","a"], "🕷️")]),
            Lesson(id: "es_w6_4", title: "más palabras", icon: "🦋",
                   words: [w("mariposa", ["m","a","r","i","p","o","s","a"], "🦋"),
                           w("elefante", ["e","l","e","f","a","n","t","e"], "🐘"),
                           w("manzana", ["m","a","n","z","a","n","a"], "🍎")]),
        ])

        // STORIES
        let stories = Unit(id: "es_stories", title: "Cuentos", colorA: "#FF6B9A", colorB: "#FFCD3C", lessons: [
            Lesson(id: "es_st_1", title: "El gato", icon: "🐱",
                   sentences: [["el","gato"],
                               ["el","gato","ve","la","luna"],
                               ["el","gato","ve","la","casa"],
                               ["¡fin!"]]),
            Lesson(id: "es_st_2", title: "El perro", icon: "🐶",
                   sentences: [["mi","perro"],
                               ["mi","perro","ve","la","pelota"],
                               ["el","perro","va","a","casa"],
                               ["¡fin!"]]),
            Lesson(id: "es_st_3", title: "La niña", icon: "👧",
                   sentences: [["la","niña","ve","el","sol"],
                               ["la","niña","va","al","mar"],
                               ["la","niña","ve","una","foca"],
                               ["¡fin!"]]),
            Lesson(id: "es_st_4", title: "La cena", icon: "🍽️",
                   sentences: [["mamá","va","a","casa"],
                               ["mamá","ve","el","queso"],
                               ["mamá","ve","el","pan"],
                               ["mamá","come","la","cena"],
                               ["¡fin!"]]),
            Lesson(id: "es_st_5", title: "La luna", icon: "🌙",
                   sentences: [["el","oso","ve","el","cielo"],
                               ["el","oso","ve","la","luna"],
                               ["la","luna","va","con","el","oso"],
                               ["¡fin!"]]),
            Lesson(id: "es_st_6", title: "El pato", icon: "🦆",
                   sentences: [["el","pato","ve","el","mar"],
                               ["el","pato","va","al","mar"],
                               ["el","pato","ve","una","foca"],
                               ["el","pato","y","la","foca"],
                               ["¡fin!"]]),
            Lesson(id: "es_st_7", title: "La llama", icon: "🦙",
                   sentences: [["mi","llama"],
                               ["la","llama","ve","la","uva"],
                               ["la","llama","come","la","uva"],
                               ["la","llama","ve","la","pera"],
                               ["la","llama","come","la","pera"],
                               ["¡fin!"]]),
            Lesson(id: "es_st_8", title: "El oso come", icon: "🐻",
                   sentences: [["el","oso","ve","la","manzana"],
                               ["el","oso","come","la","manzana"],
                               ["el","oso","ve","la","piña"],
                               ["el","oso","come","la","piña"],
                               ["¡fin!"]]),
            Lesson(id: "es_st_9", title: "El coche", icon: "🚗",
                   sentences: [["mi","papá","y","el","coche"],
                               ["papá","va","con","el","coche"],
                               ["papá","va","al","mar"],
                               ["papá","ve","el","sol"],
                               ["¡fin!"]]),
            Lesson(id: "es_st_10", title: "La mariposa", icon: "🦋",
                   sentences: [["la","niña","ve","una","mariposa"],
                               ["la","mariposa","va","al","cielo"],
                               ["la","mariposa","ve","el","girasol"],
                               ["la","mariposa","y","el","girasol"],
                               ["¡fin!"]]),
            Lesson(id: "es_st_11", title: "El pollo", icon: "🐔",
                   sentences: [["mi","pollo"],
                               ["el","pollo","ve","el","pan"],
                               ["el","pollo","come","el","pan"],
                               ["el","pollo","va","a","casa"],
                               ["¡fin!"]]),
            Lesson(id: "es_st_12", title: "La araña", icon: "🕷️",
                   sentences: [["una","araña","y","la","torre"],
                               ["la","araña","ve","la","torre"],
                               ["la","araña","va","a","la","torre"],
                               ["la","araña","ve","el","cielo"],
                               ["¡fin!"]]),
            Lesson(id: "es_st_13", title: "El niño come", icon: "👦",
                   sentences: [["el","niño","va","a","casa"],
                               ["el","niño","ve","la","leche"],
                               ["el","niño","ve","el","queso"],
                               ["el","niño","come","la","cena"],
                               ["¡fin!"]]),
            Lesson(id: "es_st_14", title: "La vaca y la luna", icon: "🐄",
                   sentences: [["mi","vaca"],
                               ["la","vaca","ve","el","cielo"],
                               ["la","vaca","ve","la","luna"],
                               ["la","luna","va","con","la","vaca"],
                               ["¡fin!"]]),
        ])

        return [u1, u2, u3, u4, u5, u6, stories]
    }()
}