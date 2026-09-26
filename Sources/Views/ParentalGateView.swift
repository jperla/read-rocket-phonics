import SwiftUI

/// A local grown-ups gate for external sharing and protected settings.
struct ParentalGate: Identifiable {
    let id = UUID()
    let a = Int.random(in: 3...9)
    let b = Int.random(in: 3...9)

    var answer: Int { a * b }

    var prompt: String {
        let words = ["", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
        return "For grown-ups: what is \(words[a]) x \(words[b])?"
    }
}

struct ParentalGateView: View {
    let gate: ParentalGate
    let done: (Bool) -> Void

    @State private var entry = ""

    var body: some View {
        ZStack {
            Theme.background(Theme.bgTop, Theme.bgBottom)

            VStack(spacing: 22) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(.white)

                Text(gate.prompt)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                TextField("Answer", text: $entry)
                    .keyboardType(.numberPad)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .frame(width: 160)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 14).fill(.white))
                    .accessibilityIdentifier("gate_answer")

                HStack(spacing: 16) {
                    Button("Cancel") { done(false) }
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Button("OK") { done(Int(entry) == gate.answer) }
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Theme.coral))
                        .accessibilityIdentifier("gate_ok")
                }
            }
            .padding(30)
        }
    }
}
