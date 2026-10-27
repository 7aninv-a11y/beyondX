import SwiftUI

private let ideaCardColor = Color(hex: "FFF4CB")
private let backButtonColor = Color(hex: "F1EEE0")

// MARK: - Screen

struct Level1View: View {
    private let maxIdeas = 3
    private let prompt = "What if humans could fly for 10 minutes every day?"

    var stars: Int = 30
    var onComplete: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var ideas: [String] = []
    @State private var draft = ""
    @State private var showReward = false
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            Color.aappBackground
                .ignoresSafeArea()
                .onTapGesture { isFocused = false }

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 42)
                    .padding(.top, 12)

                // Title
                Text("What If ...?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.top, 14)

                Text("Write 3 different ideas !")
                    .font(.system(size: 17))
                    .foregroundStyle(Color(white: 0.25))
                    .padding(.top, 14)

                // Illustration (image named "FlyingIdea" in Assets)
                Image("FlyingIdea")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 314)
                    .padding(.horizontal, 44)
                    .padding(.top, 60)

                // Question
                Text(prompt)
                    .font(.system(size: 14))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)
                    .padding(.top, 14)

                // Ideas + add field
                VStack(spacing: 8) {
                    ForEach(Array(ideas.enumerated()), id: \.offset) { _, idea in
                        IdeaRow(text: idea, fill: ideaCardColor)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if ideas.count < maxIdeas {
                        addField
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 41)
                .padding(.top, 70)

                Spacer(minLength: 16)

                // Done (appears after the first idea)
                if !ideas.isEmpty {
                    DoneButton(action: finish)
                        .padding(.bottom, 30)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: ideas)
        .fullScreenCover(isPresented: $showReward) {
            RewardPopupView(
                xp: 10,
                coins: 350,
                stars: stars,
                tip: "Try looking at the object from a different place, like home, school or outdoors .",
                onDone: {
                    onComplete()
                }
            )
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(backButtonColor))
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color(hex: "F5C518"))
                Text("\(stars)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 12)
            .frame(height: 33)
            .background(
                Capsule()
                    .fill(ideaCardColor)
                    .overlay(Capsule().strokeBorder(Color.lockedBorder, lineWidth: 1))
            )
        }
    }

    // MARK: Add field

    private var addField: some View {
        TextField("", text: $draft, prompt: Text("+ Add Text").foregroundColor(.gray))
            .font(.system(size: 17))
            .multilineTextAlignment(.center)
            .focused($isFocused)
            .submitLabel(.done)
            .onSubmit(addIdea)
            .frame(height: 47)
            .contentShape(Rectangle())
            .onTapGesture { isFocused = true }
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.gray.opacity(0.6),
                                  style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            )
    }

    // MARK: Actions

    private func addIdea() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, ideas.count < maxIdeas else { return }
        ideas.append(trimmed)
        draft = ""
    }

    private func finish() {
        showReward = true
    }
}

// MARK: - Components

private struct IdeaRow: View {
    let text: String
    let fill: Color

    var body: some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundStyle(.black)
            .lineLimit(2)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 47)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(fill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.lockedBorder, lineWidth: 1)
                    )
            )
    }
}

private struct DoneButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Done")
                .font(.system(size: 17))
                .foregroundStyle(.white)
                .frame(width: 144, height: 50)
                .background(Capsule().fill(Color.primaryOrange))
        }
    }
}

// MARK: - Preview

#Preview {
    Level1View()
}
