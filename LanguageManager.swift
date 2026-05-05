import Foundation
import SwiftUI
import Combine

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var selectedLanguage: String {
        didSet {
            UserDefaults.standard.set(selectedLanguage, forKey: "selectedLanguage")
        }
    }
    
    // Daftar bahasa yang didukung (Kode ISO)
    // en = English, id = Indonesia
    let supportedLanguages = ["en", "id"]
    
    var locale: Locale {
        return Locale(identifier: selectedLanguage)
    }
    
    init() {
        self.selectedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "en"
    }
    
    // Fungsi untuk mengubah bahasa
    func setLanguage(_ lang: String) {
        if supportedLanguages.contains(lang) {
            withAnimation {
                selectedLanguage = lang
            }
        }
    }
}
