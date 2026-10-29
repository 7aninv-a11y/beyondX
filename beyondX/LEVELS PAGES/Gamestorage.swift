import SwiftUI

// =====================================================
// حفظ بيانات اللعبة في الجوال (أوفلاين)
// =====================================================

// MARK: - حفظ البيانات (UserDefaults)

// النجوم: نحفظها بـ @AppStorage مباشرة في أي صفحة بهذا المفتاح:
//     @AppStorage(GameStorage.starsKey) private var totalStars = 0
//
// الأفكار: نحفظ أفكار كل ليفل لحاله:
//     GameStorage.saveIdeas(ideas, level: 1)
//     ideas = GameStorage.loadIdeas(level: 1)
enum GameStorage {

    // اسم المفتاح اللي تنحفظ فيه النجوم (نفس الاسم في كل الصفحات)
    static let starsKey = "totalStars"

    // نحفظ أفكار الليفل
    static func saveIdeas(_ ideas: [String], level: Int) {
        UserDefaults.standard.set(ideas, forKey: "level\(level)_ideas")
    }

    // نرجّع أفكار الليفل المحفوظة (ولو ما فيه شي نرجع مصفوفة فاضية)
    static func loadIdeas(level: Int) -> [String] {
        UserDefaults.standard.stringArray(forKey: "level\(level)_ideas") ?? []
    }
}


// MARK: - ليفل ٢: الإجابة + النجوم اللي انعطت

extension GameStorage {

    // نحفظ إجابة الليفل (مثلاً ليفل ٢: "This is not a stop sign this is ...")
    static func saveAnswer(_ answer: String, level: Int) {
        UserDefaults.standard.set(answer, forKey: "level\(level)_answer")
    }

    // نرجّع الإجابة المحفوظة (ولو ما فيه شي نرجع نص فاضي)
    static func loadAnswer(level: Int) -> String {
        UserDefaults.standard.string(forKey: "level\(level)_answer") ?? ""
    }

    // كم نجمة أخذ اليوزر من هالليفل لين الحين (عشان نزيد أو ننقص صح)
    static func starsGiven(level: Int) -> Int {
        UserDefaults.standard.integer(forKey: "level\(level)_starsGiven")
    }

    static func setStarsGiven(_ stars: Int, level: Int) {
        UserDefaults.standard.set(stars, forKey: "level\(level)_starsGiven")
    }

    // هل خلّص الليفل؟ (بعدها نثبّت النجوم وما تنقص)
    static func isLevelCompleted(_ level: Int) -> Bool {
        UserDefaults.standard.bool(forKey: "level\(level)_completed")
    }

    static func markLevelCompleted(_ level: Int) {
        UserDefaults.standard.set(true, forKey: "level\(level)_completed")
    }
}


// MARK: - تصفير اللعبة (بعد ما يخلص كل الليفلات)

extension GameStorage {

    /// يمسح كل شي محفوظ: النجوم + أفكار كل الليفلات + إجابة ليفل ٢ + النجوم اللي انعطت
    /// نستدعيه بس لما يخلص اللعبة كاملة (زر Done في صفحة الاحتفال)
    static func resetAll() {
        let defaults = UserDefaults.standard

        // نمر على كل شي محفوظ، ونمسح اللي يخص اللعبة بس
        for key in defaults.dictionaryRepresentation().keys {
            if key == starsKey || key.hasPrefix("level") {
                defaults.removeObject(forKey: key)
            }
        }
    }
}
