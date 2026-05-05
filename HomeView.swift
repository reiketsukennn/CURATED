import SwiftUI
import FirebaseAuth
import Combine
import MapKit
import CoreLocation

// MARK: - Shared Data Models
struct CarouselItem: Hashable {
    let title: String
    let image: String
}

struct Review: Identifiable, Hashable {
    let id = UUID()
    let user: String
    let rating: Double
    let comment: String
    let date: String
    let userImage: String
}

struct Restaurant: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let location: String
    let priceRange: String
    let status: String
    let imageURL: String
    let categories: [String]
    let amenities: [String]
    let latitude: Double
    let longitude: Double
    let description: String
    let vibe: String
    let specialty: String
    let galleryImages: [String]
    var reviews: [Review]
    let rating: Double
}

// MARK: - Review Management
class ReviewStore: ObservableObject {
    @Published var addedReviews: [UUID: [Review]] = [:]
    
    static let shared = ReviewStore() // For easier access if needed
    
    func addReview(_ review: Review, to restaurantId: UUID) {
        if addedReviews[restaurantId] == nil {
            addedReviews[restaurantId] = []
        }
        addedReviews[restaurantId]?.insert(review, at: 0)
    }
    
    func getReviews(for restaurant: Restaurant) -> [Review] {
        let extra = addedReviews[restaurant.id] ?? []
        return extra + restaurant.reviews
    }
}


struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var languageManager: LanguageManager
    @StateObject private var reviewStore = ReviewStore()
    
    // State for Search
    @State private var searchText = ""
    @State private var selectedFilter = "Breakfast" {
        didSet {
            // Sync category index when filter changes
            if let index = mainCategories.firstIndex(of: selectedFilter) {
                currentCategoryIndex = index
            }
        }
    }
    
    // Swipe gesture state for categories
    @State private var categoryDragOffset: CGFloat = 0
    @State private var currentCategoryIndex: Int = 0
    
    // Auto-Scroll State
    @State private var carouselIndex = 0
    @State private var curatedCardsIndex = 0
    @State private var dragOffset: CGFloat = 0
    @State private var showNotifications = false
    @State private var hasNotifications = true
    @State private var showFilterModal = false
    @State private var selectedTab = 0
    @State private var isTabBarPressed = false
    @State private var isKeyboardVisible = false
    @State private var showExploreAll = false
    @State private var favoriteRestaurantIds: Set<UUID> = {
        if let data = UserDefaults.standard.data(forKey: "savedFavorites"),
           let decoded = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            return decoded
        }
        return []
    }()
    
    // Transition for filter switching
    @State private var filterTransition: AnyTransition = .opacity
    
    // State for showing Detail View
    @State private var selectedRestaurantForDetail: Restaurant? = nil
    
    // Notification logic
    @State private var unreadCount: Int = 3
    
    // Screen Width Helper for iOS 16+ where UIScreen.main is deprecated
    private var screenWidth: CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene ?? scenes.first as? UIWindowScene
        return windowScene?.screen.bounds.width ?? 393
    }
    
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    // Models are now in Models.swift

    struct Notification: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let message: String
        let time: String
        let type: NotificationType
        var isRead: Bool
    }
    
    enum NotificationType: String, Hashable {
        case promo = "tag.fill"
        case reservation = "calendar.badge.clock"
        case recommendation = "sparkles"
        case weather = "cloud.rain.fill"
        case system = "bell.badge.fill"
    }
    
    // Filter Categories - Main swipeable categories
    let mainCategories = ["Breakfast", "Brunch", "Lunch", "Dinner"]
    let filters = ["All", "Breakfast", "Brunch", "Lunch", "Dinner", "Coffee", "Bar", "Japanese", "Indonesian", "Western", "Thai"]
    let dummyNotifications = [
        Notification(title: "New for You", message: "Checkout 5 new hidden gems in Canggu that match your taste.", time: "2m ago", type: .recommendation, isRead: false),
        Notification(title: "Booking Confirmed", message: "Your table at Copenhagen is ready for 12:30 PM. Enjoy!", time: "1h ago", type: .reservation, isRead: true),
        Notification(title: "Special Offer", message: "Get 20% OFF on all ramen at Red Dragon tonight.", time: "3h ago", type: .promo, isRead: true),
        Notification(title: "Weather Alert", message: "Heavy rain in Seminyak. Stay warm with some Pho nearby?", time: "5h ago", type: .weather, isRead: true)
    ]

    // Real Bali Data with Coordinates
    let allRestaurants: [Restaurant] = [
        Restaurant(
            name: "RÜYA",
            location: "Jl. Majapahit No. 81, Kuta",
            priceRange: "40k - 180k",
            status: "NEW",
            imageURL: "https://images.unsplash.com/photo-1543007630-9710e4a00a20?auto=format&fit=crop&w=800&q=80",
            categories: ["Turkish", "Coffee", "Shisha"],
            amenities: ["ac", "wifi", "outdoor", "halal"],
            latitude: -8.7114791,
            longitude: 115.1771744,
            description: "A dream of Anatolia in the heart of Kuta. Authentic Turkish coffee brewed on sand, artisanal pastries, and a soulful atmosphere perfect for an evening escape.",
            vibe: "Soulful",
            specialty: "Turkish Coffee",
            galleryImages: [
                "https://images.unsplash.com/photo-1543007630-9710e4a00a20?auto=format&fit=crop&w=800&q=80",
                "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80"
            ],
            reviews: [
                Review(user: "Zuan", rating: 5.0, comment: "Authentic Turkish vibes in the heart of Bali. The coffee and pastries are exceptional. Highly recommended for a soulful evening.", date: "Today", userImage: "Zuan")
            ],
            rating: 4.8
        ),
        Restaurant(
            name: "Red Dragon Ramen",
            location: "Jl. Dewi Sri, Legian",
            priceRange: "50k - 120k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=800&q=80",
            categories: ["Japanese", "Dinner"],
            amenities: ["ac", "wifi"],
            latitude: -8.7032,
            longitude: 115.1786,
            description: "Famous for its rich, creamy Hakata-style tonkotsu broth and handmade noodles. A must-visit for authentic ramen lovers in Bali.",
            vibe: "Authentic",
            specialty: "Tonkotsu Ramen",
            galleryImages: [
                "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=800&q=80",
                "https://images.unsplash.com/photo-1552611052-33e04de081de?auto=format&fit=crop&w=800&q=80",
                "https://images.unsplash.com/photo-1591814448473-7af27fe553b2?auto=format&fit=crop&w=800&q=80"
            ],
            reviews: [
                Review(user: "Sanjeev M.", rating: 5.0, comment: "Best ramen in Bali! The broth is so rich and authentic. Must try the spicy dragon bowl.", date: "2 days ago", userImage: "https://i.pravatar.cc/150?u=sanj"),
                Review(user: "Yuki Tanaka", rating: 4.5, comment: "Reminds me of home. Very good service and taste.", date: "1 week ago", userImage: "https://i.pravatar.cc/150?u=yuki"),
                Review(user: "Alex Chen", rating: 4.8, comment: "Incredible depth of flavor. The noodles are handmade and it shows.", date: "2 weeks ago", userImage: "https://i.pravatar.cc/150?u=alex"),
                Review(user: "Budi Santoso", rating: 4.0, comment: "Great place for dinner. A bit crowded during weekends but worth the wait.", date: "3 weeks ago", userImage: "https://i.pravatar.cc/150?u=budi")
            ],
            rating: 4.9
        ),
        Restaurant(
            name: "Copenhagen Canggu",
            location: "Jl. Canggu Padang Linjong",
            priceRange: "25k - 150k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=800&q=80",
            categories: ["Breakfast", "Brunch", "Coffee"],
            amenities: ["ac", "wifi", "pet", "outdoor"],
            latitude: -8.6480,
            longitude: 115.1310,
            description: "Nordic-inspired breakfast and brunch spot. Known for their build-your-own board and legendary cinnamon rolls in a minimalist setting.",
            vibe: "Minimalist",
            specialty: "Cinnamon Rolls",
            galleryImages: [
                "https://images.unsplash.com/photo-1600093463592-8e36ae95ef56?auto=format&fit=crop&w=800&q=80",
                "https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=800&q=80",
                "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=800&q=80"
            ],
            reviews: [
                Review(user: "Sarah J.", rating: 4.8, comment: "The cinnamon rolls are to die for! Perfect brunch spot.", date: "1 day ago", userImage: "https://i.pravatar.cc/150?u=sarah"),
                Review(user: "Mike Ross", rating: 4.0, comment: "Cozy vibe, good coffee. Can get busy on weekends.", date: "3 days ago", userImage: "https://i.pravatar.cc/150?u=mike"),
                Review(user: "Jessica P.", rating: 5.0, comment: "Favorite spot in Canggu for a slow morning. The bread is fresh baked.", date: "1 week ago", userImage: "https://i.pravatar.cc/150?u=jess"),
                Review(user: "Tom H.", rating: 4.2, comment: "Solid coffee and great selection of pastries. The outdoor area is lovely.", date: "2 weeks ago", userImage: "https://i.pravatar.cc/150?u=tom")
            ],
            rating: 4.8
        ),
        Restaurant(
            name: "Crate Cafe",
            location: "Jl. Canggu Padang Linjong",
            priceRange: "35k - 80k",
            status: "BUSY",
            imageURL: "https://images.unsplash.com/photo-1559339352-11d035aa65de?auto=format&fit=crop&w=800&q=80",
            categories: ["Breakfast", "Brunch", "Coffee"],
            amenities: ["wifi", "outdoor", "parking"],
            latitude: -8.6492,
            longitude: 115.1320,
            description: "Industrial vibes meet huge portions. Crate is a Canggu institution for artists, surfers, and breakfast enthusiasts.",
            vibe: "Industrial",
            specialty: "Smoothie Bowls",
            galleryImages: [
                "https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=800&q=80",
                "https://images.unsplash.com/photo-1559339352-11d035aa65de?auto=format&fit=crop&w=800&q=80",
                "https://images.unsplash.com/photo-1501339817302-3e27163b7d34?auto=format&fit=crop&w=800&q=80"
            ],
            reviews: [
                Review(user: "Liam N.", rating: 4.5, comment: "Huge portions and very affordable. Music is great!", date: "1 week ago", userImage: "https://i.pravatar.cc/150?u=liam")
            ],
            rating: 4.6
        ),
        Restaurant(
            name: "Ulekan",
            location: "Berawa",
            priceRange: "80k - 200k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=800&q=80",
            categories: ["Indonesian", "Dinner"],
            amenities: ["ac", "wifi", "parking", "halal"],
            latitude: -8.6620,
            longitude: 115.1432,
            description: "Authentic Indonesian cuisine prepared with artisanal flair. Experience the real taste of the archipelago in a beautiful setting.",
            vibe: "Cultural",
            specialty: "Nasi Campur",
            galleryImages: [
                "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=800&q=80",
                "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=800&q=80"
            ],
            reviews: [
                Review(user: "Dewi S.", rating: 5.0, comment: "Authentic Indonesian flavors in a premium setting.", date: "2 days ago", userImage: "https://i.pravatar.cc/150?u=dewi")
            ],
            rating: 4.9
        ),
        Restaurant(
            name: "Monsieur Spoon",
            location: "Jl. Pantai Batu Bolong",
            priceRange: "30k - 120k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=800&q=80",
            categories: ["Breakfast", "Coffee"],
            amenities: ["ac", "wifi", "pet"],
            latitude: -8.6515,
            longitude: 115.1278,
            description: "Authentic French bakery and cafe. Known for the best croissants in Bali and a charming garden atmosphere.",
            vibe: "French Chic",
            specialty: "Croissants",
            galleryImages: [
                "https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?auto=format&fit=crop&w=800&q=80",
                "https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=800&q=80"
            ],
            reviews: [
                Review(user: "Pierre", rating: 4.7, comment: "Best croissants in Bali. Hands down.", date: "4 days ago", userImage: "https://i.pravatar.cc/150?u=pierre")
            ],
            rating: 4.7
        ),
        Restaurant(
            name: "Motel Mexicola",
            location: "Seminyak",
            priceRange: "100k - 350k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=800&q=80",
            categories: ["Bar", "Dinner"],
            amenities: ["ac", "bar", "outdoor", "parking"],
            latitude: -8.6800,
            longitude: 115.1550,
            description: "A colorful burst of Mexican culture and cuisine. Famous for its vibrant parties, tacos, and incredible tequila selection.",
            vibe: "Energetic",
            specialty: "Fish Tacos",
            galleryImages: [
                "https://images.unsplash.com/photo-1560624052-449f5ddf0c78?auto=format&fit=crop&w=800&q=80",
                "https://images.unsplash.com/photo-1571091718767-18b5b1457add?auto=format&fit=crop&w=800&q=80"
            ],
            reviews: [
                Review(user: "Rico", rating: 4.5, comment: "Amazing vibe and decor. Great for groups!", date: "1 day ago", userImage: "https://i.pravatar.cc/150?u=rico")
            ],
            rating: 4.8
        ),
        Restaurant(
            name: "Sisterfields",
            location: "Seminyak",
            priceRange: "60k - 200k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1550966841-396ad8867548?auto=format&fit=crop&w=800&q=80",
            categories: ["Brunch", "Lunch", "Coffee"],
            amenities: ["ac", "wifi", "parking"],
            latitude: -8.6840,
            longitude: 115.1570,
            description: "An iconic boutique cafe representing the modern Australian brunch culture in the heart of Seminyak.",
            vibe: "Modern",
            specialty: "Smashed Avocado",
            galleryImages: ["https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Emma", rating: 4.8, comment: "Classic Seminyak brunch spot. Never fails.", date: "1 day ago", userImage: "https://i.pravatar.cc/150?u=emma")],
            rating: 4.8
        ),
        Restaurant(
            name: "Mason",
            location: "Canggu",
            priceRange: "120k - 400k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1544148103-0773bf10d330?auto=format&fit=crop&w=800&q=80",
            categories: ["Dinner", "Western"],
            amenities: ["ac", "bar", "parking"],
            latitude: -8.6540,
            longitude: 115.1290,
            description: "Focusing on quality ingredients and traditional techniques. Wood-fired meats and handmade cheeses in a beautiful stone building.",
            vibe: "Rustic",
            specialty: "Wood-fired Ribs",
            galleryImages: ["https://images.unsplash.com/photo-1544148103-0773bf10d330?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Jack", rating: 4.9, comment: "The wood-fired dishes are incredible.", date: "3 days ago", userImage: "https://i.pravatar.cc/150?u=jack")],
            rating: 4.9
        ),
        Restaurant(
            name: "Shelter Pererenan",
            location: "Pererenan",
            priceRange: "100k - 300k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80",
            categories: ["Brunch", "Dinner"],
            amenities: ["outdoor", "wifi", "parking"],
            latitude: -8.6400,
            longitude: 115.1150,
            description: "Contemporary Middle Eastern and Mediterranean cuisine in an architectural masterpiece.",
            vibe: "Elegant",
            specialty: "Slow Roasted Lamb",
            galleryImages: ["https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Chloe", rating: 4.7, comment: "Beautiful architecture and great Middle Eastern vibes.", date: "5 days ago", userImage: "https://i.pravatar.cc/150?u=chloe")],
            rating: 4.8
        ),
        Restaurant(
            name: "Kynd Community",
            location: "Seminyak",
            priceRange: "50k - 150k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1534422298391-e4f8c170db0f?auto=format&fit=crop&w=800&q=80",
            categories: ["Breakfast", "Brunch", "Western"],
            amenities: ["ac", "wifi", "pet"],
            latitude: -8.6750,
            longitude: 115.1520,
            description: "World famous plant-based cafe. Helping you show the world how good vegan food can taste.",
            vibe: "Playful",
            specialty: "Berry Smoothie Bowl",
            galleryImages: ["https://images.unsplash.com/photo-1490818387583-1baba5e638af?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Bella", rating: 4.6, comment: "So colorful and the vegan options are the best!", date: "1 week ago", userImage: "https://i.pravatar.cc/150?u=bella")],
            rating: 4.7
        ),
        Restaurant(
            name: "Nalu Bowls",
            location: "Seminyak",
            priceRange: "40k - 90k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=800&q=80",
            categories: ["Breakfast", "Brunch"],
            amenities: ["outdoor", "wifi"],
            latitude: -8.6820,
            longitude: 115.1580,
            description: "Bali's first smoothie bowl shack. Inspired by Hawaii and local ingredients.",
            vibe: "Tropical",
            specialty: "J-Bay Bowl",
            galleryImages: ["https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Dan", rating: 4.5, comment: "Perfect acai bowls for a hot morning.", date: "2 weeks ago", userImage: "https://i.pravatar.cc/150?u=dan")],
            rating: 4.6
        ),
        Restaurant(
            name: "Penny Lane",
            location: "Jl. Munduk Catu, Canggu",
            priceRange: "70k - 250k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1533777857889-4be7c70b33f7?auto=format&fit=crop&w=800&q=80",
            categories: ["Lunch", "Dinner", "Western"],
            amenities: ["ac", "bar", "parking", "outdoor"],
            latitude: -8.6520,
            longitude: 115.1300,
            description: "A stunning Roman-inspired oasis in Canggu. Incredible architecture and a diverse international menu.",
            vibe: "Grand",
            specialty: "Greek Salad",
            galleryImages: ["https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Liam", rating: 4.9, comment: "The architecture is mind-blowing. Great food too!", date: "1 day ago", userImage: "https://i.pravatar.cc/150?u=liam")],
            rating: 4.9
        ),
        Restaurant(
            name: "Milk & Madu",
            location: "Jl. Pantai Berawa",
            priceRange: "50k - 180k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=800&q=80",
            categories: ["Breakfast", "Brunch", "Lunch"],
            amenities: ["ac", "wifi", "parking", "pet"],
            latitude: -8.6630,
            longitude: 115.1400,
            description: "The neighborhood's favorite meeting spot. Amazing coffee, all-day breakfast, and legendary pizzas.",
            vibe: "Family Friendly",
            specialty: "Lava Stone Pizza",
            galleryImages: ["https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Sophie", rating: 4.7, comment: "Best family cafe in Bali. The pizzas are a must-try.", date: "2 days ago", userImage: "https://i.pravatar.cc/150?u=sophie")],
            rating: 4.7
        ),
        Restaurant(
            name: "The Lawn",
            location: "Jl. Pura Dalem, Canggu",
            priceRange: "100k - 450k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1533777857889-4be7c70b33f7?auto=format&fit=crop&w=800&q=80",
            categories: ["Bar", "Dinner", "Western"],
            amenities: ["outdoor", "bar", "parking"],
            latitude: -8.6550,
            longitude: 115.1270,
            description: "Canggu's premier beach club. Cocktails, food, and the best sunset views in town.",
            vibe: "Beachfront",
            specialty: "Canggu Mule",
            galleryImages: ["https://images.unsplash.com/photo-1533777857889-4be7c70b33f7?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Tom", rating: 4.5, comment: "Sunset views here are unbeatable.", date: "3 days ago", userImage: "https://i.pravatar.cc/150?u=tom")],
            rating: 4.6
        ),
        Restaurant(
            name: "Bebek Tepi Sawah",
            location: "Jl. Raya Goa Gajah, Ubud",
            priceRange: "90k - 200k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=800&q=80",
            categories: ["Indonesian", "Lunch", "Dinner"],
            amenities: ["outdoor", "parking", "halal"],
            latitude: -8.5230,
            longitude: 115.2750,
            description: "Traditional Balinese dining amidst the rice fields. Famous for its crispy fried duck.",
            vibe: "Traditional",
            specialty: "Crispy Duck",
            galleryImages: ["https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Adi", rating: 4.8, comment: "Crispy duck is legendary. Pure Bali vibes.", date: "1 week ago", userImage: "https://i.pravatar.cc/150?u=adi")],
            rating: 4.8
        ),
        Restaurant(
            name: "Revolver Espresso",
            location: "Jl. Kayu Aya, Seminyak",
            priceRange: "35k - 150k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=800&q=80",
            categories: ["Coffee", "Breakfast", "Brunch"],
            amenities: ["ac", "wifi", "bar"],
            latitude: -8.6835,
            longitude: 115.1565,
            description: "A hidden coffee powerhouse with a rebellious spirit. Arguably the best beans in Seminyak.",
            vibe: "Boutique",
            specialty: "Revolver Espresso",
            galleryImages: ["https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Kate", rating: 4.9, comment: "Best coffee in Seminyak. Secret entrance is cool!", date: "2 weeks ago", userImage: "https://i.pravatar.cc/150?u=kate")],
            rating: 4.9
        ),
        Restaurant(
            name: "Sardine",
            location: "Jl. Petitenget, Kerobokan",
            priceRange: "150k - 500k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80",
            categories: ["Dinner", "Seafood", "Western"],
            amenities: ["outdoor", "parking", "bar"],
            latitude: -8.6720,
            longitude: 115.1550,
            description: "Elegant dining overlooking emerald rice fields. Fresh seafood and organic produce from their own farm.",
            vibe: "Serene",
            specialty: "Grilled Snapper",
            galleryImages: ["https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Marc", rating: 4.8, comment: "Dinner with a view of the rice fields is magical.", date: "1 day ago", userImage: "https://i.pravatar.cc/150?u=marc")],
            rating: 4.8
        ),
        Restaurant(
            name: "Barbacoa",
            location: "Jl. Petitenget, Kerobokan",
            priceRange: "120k - 450k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1544148103-0773bf10d330?auto=format&fit=crop&w=800&q=80",
            categories: ["Dinner", "Western"],
            amenities: ["ac", "bar", "parking"],
            latitude: -8.6710,
            longitude: 115.1560,
            description: "Specializing in charcoal-grilled meats and Latin American flavors. A feast for the senses.",
            vibe: "Lively",
            specialty: "8-Hour Wood-fired Lamb",
            galleryImages: ["https://images.unsplash.com/photo-1544148103-0773bf10d330?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Elena", rating: 4.7, comment: "The lamb is to die for. Incredible atmosphere.", date: "3 days ago", userImage: "https://i.pravatar.cc/150?u=elena")],
            rating: 4.7
        ),
        Restaurant(
            name: "Da Maria",
            location: "Jl. Petitenget, Seminyak",
            priceRange: "100k - 300k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80",
            categories: ["Dinner", "Bar", "Western"],
            amenities: ["ac", "bar", "wifi"],
            latitude: -8.6730,
            longitude: 115.1540,
            description: "Modern Italian restaurant and bar that captures the spirit of the Amalfi Coast.",
            vibe: "Italian Party",
            specialty: "Neapolitan Pizza",
            galleryImages: ["https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Luca", rating: 4.6, comment: "Best pizza and vibes in Seminyak. Feels like Italy!", date: "5 days ago", userImage: "https://i.pravatar.cc/150?u=luca")],
            rating: 4.6
        ),
        Restaurant(
            name: "L’Osteria",
            location: "Jl. Pantai Batu Bolong, Canggu",
            priceRange: "80k - 200k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1533777857889-4be7c70b33f7?auto=format&fit=crop&w=800&q=80",
            categories: ["Lunch", "Dinner", "Western"],
            amenities: ["ac", "wifi", "parking"],
            latitude: -8.6530,
            longitude: 115.1310,
            description: "Traditional Italian recipes and sourdough pizzas in a cozy, rustic setting.",
            vibe: "Cozy Italian",
            specialty: "Sourdough Pizza",
            galleryImages: ["https://images.unsplash.com/photo-1533777857889-4be7c70b33f7?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Gia", rating: 4.9, comment: "Authentic sourdough pizza. Simply the best.", date: "1 week ago", userImage: "https://i.pravatar.cc/150?u=gia")],
            rating: 4.9
        ),
        Restaurant(
            name: "Shady Shack",
            location: "Jl. Tanah Barak, Canggu",
            priceRange: "45k - 120k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1490818387583-1baba5e638af?auto=format&fit=crop&w=800&q=80",
            categories: ["Breakfast", "Lunch", "Brunch"],
            amenities: ["outdoor", "wifi", "pet"],
            latitude: -8.6510,
            longitude: 115.1280,
            description: "A vegetarian paradise in the heart of Canggu. Fresh, healthy, and colorful food.",
            vibe: "Bohemian",
            specialty: "The Shady Bowl",
            galleryImages: ["https://images.unsplash.com/photo-1490818387583-1baba5e638af?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Maya", rating: 4.8, comment: "Healthy, fresh, and delicious. My daily spot.", date: "2 weeks ago", userImage: "https://i.pravatar.cc/150?u=maya")],
            rating: 4.8
        ),
        Restaurant(
            name: "La Lucciola",
            location: "Seminyak Beach",
            priceRange: "150k - 450k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80",
            categories: ["Lunch", "Dinner", "Western"],
            amenities: ["outdoor", "bar", "parking"],
            latitude: -8.6780,
            longitude: 115.1510,
            description: "An elegant classic on the Petitenget shoreline. Fine dining with ocean views.",
            vibe: "Elegant Beachside",
            specialty: "Seafood Linguine",
            galleryImages: ["https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Gia", rating: 4.9, comment: "The best beachside dining in Seminyak. Pure elegance.", date: "1 day ago", userImage: "https://i.pravatar.cc/150?u=gia")],
            rating: 4.9
        ),
        Restaurant(
            name: "Baked",
            location: "Jl. Raya Pererenan",
            priceRange: "40k - 120k",
            status: "BUSY",
            imageURL: "https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=800&q=80",
            categories: ["Breakfast", "Coffee", "Brunch"],
            amenities: ["ac", "wifi", "pet"],
            latitude: -8.6350,
            longitude: 115.1250,
            description: "Arguably the best sourdough and baked goods in the Pererenan area.",
            vibe: "Hipster",
            specialty: "Sourdough Toasties",
            galleryImages: ["https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Leo", rating: 4.8, comment: "Scrambled eggs here are legendary.", date: "3 days ago", userImage: "https://i.pravatar.cc/150?u=leo")],
            rating: 4.8
        ),
        Restaurant(
            name: "Woods Pererenan",
            location: "Jl. Pantai Pererenan",
            priceRange: "100k - 300k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1533777857889-4be7c70b33f7?auto=format&fit=crop&w=800&q=80",
            categories: ["Brunch", "Dinner", "Western"],
            amenities: ["ac", "bar", "parking", "outdoor"],
            latitude: -8.6380,
            longitude: 115.1200,
            description: "Stunning wooden architecture and a menu that focuses on fresh, seasonal ingredients.",
            vibe: "Architectural",
            specialty: "Jazz Brunch",
            galleryImages: ["https://images.unsplash.com/photo-1533777857889-4be7c70b33f7?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Sasha", rating: 4.7, comment: "Incredible interior design and the jazz brunch is amazing.", date: "1 week ago", userImage: "https://i.pravatar.cc/150?u=sasha")],
            rating: 4.7
        ),
        Restaurant(
            name: "Skool Kitchen",
            location: "Jl. Pura Dalem, Canggu",
            priceRange: "200k - 600k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1544148103-0773bf10d330?auto=format&fit=crop&w=800&q=80",
            categories: ["Dinner", "Western"],
            amenities: ["ac", "bar", "outdoor"],
            latitude: -8.6560,
            longitude: 115.1260,
            description: "Everything is cooked over an open fire. A primitive and precise dining experience.",
            vibe: "Sophisticated",
            specialty: "Flame-grilled Seafood",
            galleryImages: ["https://images.unsplash.com/photo-1544148103-0773bf10d330?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Mark", rating: 5.0, comment: "Everything cooked over open fire. Exceptional taste.", date: "2 days ago", userImage: "https://i.pravatar.cc/150?u=mark")],
            rating: 4.9
        ),
        Restaurant(
            name: "Yuki",
            location: "Jl. Pantai Batu Bolong",
            priceRange: "150k - 400k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1580822184713-fc5400e7fe10?auto=format&fit=crop&w=800&q=80",
            categories: ["Japanese", "Dinner", "Bar"],
            amenities: ["outdoor", "bar", "wifi"],
            latitude: -8.6580,
            longitude: 115.1280,
            description: "Modern Japanese cuisine in a stunning beachside setting.",
            vibe: "Cool Japanese",
            specialty: "Wagyu Sando",
            galleryImages: ["https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Kenji", rating: 4.9, comment: "Modern Japanese with a perfect view of the surf.", date: "4 days ago", userImage: "https://i.pravatar.cc/150?u=kenji")],
            rating: 4.8
        ),
        Restaurant(
            name: "Tanaman",
            location: "Desa Potato Head, Seminyak",
            priceRange: "120k - 350k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1490818387583-1baba5e638af?auto=format&fit=crop&w=800&q=80",
            categories: ["Dinner", "Indonesian"],
            amenities: ["ac", "bar", "parking"],
            latitude: -8.6790,
            longitude: 115.1480,
            description: "Plant-based Indonesian cuisine that respects and reinvents tradition.",
            vibe: "Futuristic",
            specialty: "Nangka Rendang",
            galleryImages: ["https://images.unsplash.com/photo-1490818387583-1baba5e638af?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Ria", rating: 4.8, comment: "Plant-based Indonesian food like you've never had before.", date: "1 week ago", userImage: "https://i.pravatar.cc/150?u=ria")],
            rating: 4.8
        ),
        Restaurant(
            name: "Zest Ubud",
            location: "Jl. Penestanan Kelod",
            priceRange: "60k - 180k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=800&q=80",
            categories: ["Breakfast", "Brunch", "Lunch"],
            amenities: ["outdoor", "wifi", "parking"],
            latitude: -8.5050,
            longitude: 115.2520,
            description: "Jungle-style dining focusing on healthy, plant-based food and high vibes.",
            vibe: "Junglist",
            specialty: "Zest Pancake",
            galleryImages: ["https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Toby", rating: 4.7, comment: "The views of the jungle and the food are equally amazing.", date: "2 days ago", userImage: "https://i.pravatar.cc/150?u=toby")],
            rating: 4.8
        ),
        Restaurant(
            name: "Clear Cafe",
            location: "Jl. Hanoman, Ubud",
            priceRange: "50k - 150k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1543353071-873f17a7a088?auto=format&fit=crop&w=800&q=80",
            categories: ["Breakfast", "Lunch", "Brunch"],
            amenities: ["ac", "wifi", "pet"],
            latitude: -8.5120,
            longitude: 115.2640,
            description: "A beautiful space with a massive menu designed to nourish your body and soul.",
            vibe: "Peaceful",
            specialty: "Raw Lasagna",
            galleryImages: ["https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Nina", rating: 4.6, comment: "Beautiful space and a massive menu with healthy options.", date: "5 days ago", userImage: "https://i.pravatar.cc/150?u=nina")],
            rating: 4.8
        ),
        Restaurant(
            name: "Sante Pererenan",
            location: "Jl. Pantai Pererenan",
            priceRange: "70k - 200k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=800&q=80",
            categories: ["Brunch", "Breakfast", "Lunch"],
            amenities: ["outdoor", "wifi", "pet"],
            latitude: -8.6390,
            longitude: 115.1210,
            description: "A cozy neighborhood cafe in Pererenan perfect for a slow breakfast.",
            vibe: "Local Cozy",
            specialty: "Eggs Benedict",
            galleryImages: ["https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Chloe", rating: 4.5, comment: "Great vibe for a slow morning in Pererenan.", date: "1 week ago", userImage: "https://i.pravatar.cc/150?u=chloe")],
            rating: 4.8
        ),
        Restaurant(
            name: "Biku",
            location: "Jl. Petitenget, Seminyak",
            priceRange: "60k - 250k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=800&q=80",
            categories: ["Lunch", "Indonesian", "Western"],
            amenities: ["ac", "wifi", "parking"],
            latitude: -8.6750,
            longitude: 115.1530,
            description: "High tea, tarot readings, and authentic Indonesian food in an ancient teak joglo.",
            vibe: "Antique",
            specialty: "Balinese High Tea",
            galleryImages: ["https://images.unsplash.com/photo-1544148103-0773bf10d330?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Hadi", rating: 4.9, comment: "Best high tea in Bali. The Nasi Campur is also top tier.", date: "3 days ago", userImage: "https://i.pravatar.cc/150?u=hadi")],
            rating: 4.8
        ),
        Restaurant(
            name: "Mosto",
            location: "Jl. Pantai Berawa",
            priceRange: "100k - 400k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80",
            categories: ["Dinner", "Bar", "Western"],
            amenities: ["ac", "bar", "wifi"],
            latitude: -8.6640,
            longitude: 115.1410,
            description: "Indonesia's first natural wine bar, offering casual dining inspired by European bistros.",
            vibe: "Bistro",
            specialty: "Natural Wine",
            galleryImages: ["https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "James", rating: 4.8, comment: "Natural wine and small plates. Best bistro in Berawa.", date: "1 day ago", userImage: "https://i.pravatar.cc/150?u=james")],
            rating: 4.8
        ),
        Restaurant(
            name: "Betterman Coffee",
            location: "Jl. Tanah Barak, Canggu",
            priceRange: "35k - 80k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1501339817302-3e27163b7d34?auto=format&fit=crop&w=800&q=80",
            categories: ["Coffee", "Breakfast"],
            amenities: ["ac", "wifi"],
            latitude: -8.6500,
            longitude: 115.1270,
            description: "Serious coffee for serious enthusiasts. Minimalist space, maximum flavor.",
            vibe: "Coffee Only",
            specialty: "Cold Brew",
            galleryImages: ["https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Sam", rating: 4.7, comment: "Hidden gem for serious coffee lovers.", date: "4 days ago", userImage: "https://i.pravatar.cc/150?u=sam")],
            rating: 4.8
        ),
        Restaurant(
            name: "Soma Ubud",
            location: "Jl. Goutama Selatan, Ubud",
            priceRange: "50k - 150k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=800&q=80",
            categories: ["Lunch", "Dinner", "Brunch"],
            amenities: ["outdoor", "wifi"],
            latitude: -8.5100,
            longitude: 115.2630,
            description: "A community space for organic food, soul music, and high vibes in the heart of Ubud.",
            vibe: "Community",
            specialty: "Soul Food Platter",
            galleryImages: ["https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Aya", rating: 4.8, comment: "Soul food in the heart of Ubud. Community vibes.", date: "6 days ago", userImage: "https://i.pravatar.cc/150?u=aya")],
            rating: 4.8
        ),
        Restaurant(
            name: "The Slow",
            location: "Jl. Pantai Batu Bolong",
            priceRange: "120k - 450k",
            status: "OPEN",
            imageURL: "https://images.unsplash.com/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=800&q=80",
            categories: ["Dinner", "Bar", "Western"],
            amenities: ["ac", "bar", "parking"],
            latitude: -8.6570,
            longitude: 115.1290,
            description: "A multi-faceted island stay, offering gourmet dining, art, and music in a brutalist setting.",
            vibe: "Brutalist",
            specialty: "Slow Cooked Ribs",
            galleryImages: ["https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80"],
            reviews: [Review(user: "Dan", rating: 4.9, comment: "Most stylish place in Canggu. Music is perfect.", date: "2 days ago", userImage: "https://i.pravatar.cc/150?u=dan")],
            rating: 4.8
        )
    ]
    
    let carouselItems: [CarouselItem] = [
        CarouselItem(title: "Copenhagen Canggu", image: "https://images.unsplash.com/photo-1600093463592-8e36ae95ef56?auto=format&fit=crop&w=800&q=80"),
        CarouselItem(title: "Red Dragon Ramen", image: "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=800&q=80"),
        CarouselItem(title: "Kopi Kenangan", image: "https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=800&q=80")
    ]
    
    var filteredRestaurants: [Restaurant] {
        allRestaurants.filter { restaurant in
            let matchesFilter = selectedFilter == "All" || restaurant.categories.contains(selectedFilter)
            let matchesSearch = searchText.isEmpty || 
                                restaurant.name.localizedCaseInsensitiveContains(searchText) || 
                                restaurant.location.localizedCaseInsensitiveContains(searchText)
            return matchesFilter && matchesSearch
        }
    }
    
    // Get restaurants for specific category with unique content per category
    func getRestaurantsForCategory(_ category: String) -> [Restaurant] {
        // Each category can have different restaurants or same restaurants with different ordering
        switch category {
        case "Breakfast":
            return allRestaurants.filter { $0.categories.contains("Breakfast") }
        case "Brunch":
            return allRestaurants.filter { $0.categories.contains("Brunch") }
        case "Lunch":
            // Lunch can include restaurants that serve lunch (Brunch, Dinner, or general)
            return allRestaurants.filter { restaurant in
                restaurant.categories.contains("Brunch") || 
                restaurant.categories.contains("Dinner") ||
                restaurant.categories.contains("Indonesian") ||
                restaurant.categories.contains("Japanese")
            }
        case "Dinner":
            return allRestaurants.filter { $0.categories.contains("Dinner") }
        default:
            return allRestaurants.filter { $0.categories.contains(category) }
        }
    }

    func toggleFavorite(_ id: UUID) {
        if favoriteRestaurantIds.contains(id) {
            favoriteRestaurantIds.remove(id)
        } else {
            favoriteRestaurantIds.insert(id)
        }
        
        if let encoded = try? JSONEncoder().encode(favoriteRestaurantIds) {
            UserDefaults.standard.set(encoded, forKey: "savedFavorites")
        }
    }
    

    var body: some View {
        ZStack {
            // Background color
            Color(hex: "FDFBF7").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Navigation Hub
                ZStack {
                    Group {
                        switch selectedTab {
                        case 0:
                            homeContent
                        case 1:
                            ExploreMapView(
                                allRestaurants: allRestaurants, 
                                selectedRestaurantForDetail: $selectedRestaurantForDetail,
                                showNotifications: $showNotifications,
                                hasNotifications: hasNotifications
                            )
                        case 2:
                            FavoritesView(allRestaurants: allRestaurants, favoriteIds: favoriteRestaurantIds, onToggleFavorite: { id in
                                toggleFavorite(id)
                            }, selectedRestaurantForDetail: $selectedRestaurantForDetail)
                        case 3:
                            ProfileView()
                        default:
                            homeContent
                        }
                    }
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                }
                .frame(maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.25), value: selectedTab)
            }
            
            // MARK: - Explore All View Overlay
            if showExploreAll {
                ExploreAllView(
                    isPresented: $showExploreAll,
                    allRestaurants: allRestaurants,
                    favoriteIds: favoriteRestaurantIds,
                    onToggleFavorite: { id in
                        toggleFavorite(id)
                    },
                    selectedRestaurantForDetail: $selectedRestaurantForDetail
                )
                .transition(.move(edge: .bottom))
                .zIndex(10) // Ensure it's on top
            }
            
            // MARK: - Notification Drawer Overlay (Slide-In from Left)
            ZStack(alignment: .leading) {
                // Blur Background
                BlurView(style: .systemThinMaterialDark)
                    .opacity(showNotifications ? 1 : 0)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            showNotifications = false
                        }
                    }
                
                // Drawer Content
                VStack(alignment: .leading, spacing: 0) {
                    // Header Area
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notifications")
                                .font(.system(size: 32, weight: .bold, design: .serif))
                                .foregroundColor(Color.black)
                            
                            Text("You have \(dummyNotifications.filter { !$0.isRead }.count) unread messages")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.black.opacity(0.4))
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            // mark all action
                        }) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(Color.black.opacity(0.3))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.black.opacity(0.05)))
                        }
                    }
                    .padding(.top, 60)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("NEWEST")
                                .font(.system(size: 12, weight: .black))
                                .kerning(1.2)
                                .foregroundColor(Color.black.opacity(0.3))
                                .padding(.top, 10)
                            
                            VStack(spacing: 14) {
                                ForEach(dummyNotifications) { note in
                                    NotificationItemView(notification: note)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 120)
                    }
                }
                .frame(width: screenWidth * 0.8)
                .padding(.leading, 100) // Add buffer for bounce overshoot
                .frame(maxHeight: .infinity)
                .background(Color(hex: "FDFBF7"))
                .clipShape(CustomCorner(corners: [.topRight, .bottomRight], radius: 35))
                .shadow(color: .black.opacity(0.15), radius: 15, x: 5, y: 0)
                .offset(x: showNotifications ? -100 : -(screenWidth * 0.8 + 150)) // Offset logic handling buffer
                .ignoresSafeArea() // Ensure full height coverage
            }
            .zIndex(100)
            .allowsHitTesting(showNotifications) // Pass through touches when hidden

            // MARK: - Advanced Filter Modal
            if showFilterModal {
                BlurView(style: .systemUltraThinMaterialDark)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showFilterModal = false
                        }
                    }
                    .zIndex(150)
                
                VStack(spacing: 20) {
                    Text("Advanced Filters")
                        .font(.title2.bold())
                        .foregroundColor(Color.black)
                    
                    Text("More options coming soon...")
                        .font(.body)
                        .foregroundColor(.gray)
                }
                .frame(width: 300, height: 250)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 20)
                .zIndex(151)
                .transition(.scale)
            }
            
            // MARK: - Floating Tab Bar
            VStack {
                Spacer()
                HStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { index in
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = index
                            }
                        }) {
                            VStack(spacing: 4) {
                                if index == 0 {
                                    // Custom Symmetrical House Icon (No Chimney, No Background)
                                    VStack(spacing: 0) {
                                        // Roof
                                        HouseRoof()
                                            .fill(selectedTab == 0 ? Color.white : Color.white.opacity(0.5))
                                            .frame(width: 22, height: 11)
                                        
                                        // Base
                                        Rectangle()
                                            .fill(selectedTab == 0 ? Color.white : Color.white.opacity(0.5))
                                            .frame(width: 17, height: 11)
                                            .overlay(
                                                Rectangle()
                                                    .fill(selectedTab == 0 ? Color.black : Color.black.opacity(0.5))
                                                    .frame(width: 5, height: 6),
                                                alignment: .bottom
                                            )
                                    }
                                    .frame(height: 26)
                                } else {
                                    Image(systemName: getTabIcon(index, isSelected: selectedTab == index))
                                        .font(.system(size: 24, weight: selectedTab == index ? .semibold : .medium))
                                        .foregroundColor(selectedTab == index ? .white : Color.white.opacity(0.5))
                                        .frame(height: 26)
                                }
                                
                                // Selection Indicator
                                if selectedTab == index {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.white)
                                        .frame(width: 22, height: 3)
                                        .transition(.scale.combined(with: .opacity))
                                } else {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.clear)
                                        .frame(width: 22, height: 3)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .background(
                    Capsule()
                        .fill(Color.black)
                        .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal, 35)
                .padding(.bottom, 25)
                .offset(y: isKeyboardVisible ? 150 : 0)
                .animation(.spring(), value: isKeyboardVisible)
            }
            .zIndex(50)
        }
        .ignoresSafeArea(edges: .top)
        .fullScreenCover(item: $selectedRestaurantForDetail) { restaurant in
            RestaurantDetailView(restaurant: restaurant)
                .environmentObject(reviewStore)
        }
        .onAppear {
            if authManager.currentUser == nil {
                authManager.fetchCurrentUser()
            }
            
            // Keyboard observers
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
                isKeyboardVisible = true
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                isKeyboardVisible = false
            }
        }
    }
    
    // MARK: - Subviews
    
    private var homeContent: some View {
        ZStack(alignment: .top) {
            // Background color for the whole view
            Color(hex: "FDFBF7").ignoresSafeArea()
            
            // Scrollable Body (behind the header)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 30) {
                    // Search and Discovery Section
                    VStack(alignment: .leading, spacing: 20) {
                        // Greeting text
                        Text("Discover the\ncurated Cafe & Resto!")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 24)
                        
                        // Search Bar
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search for a cafe...", text: $searchText)
                                .font(.system(size: 15))
                                .foregroundColor(.black)
                            
                            Button(action: { showFilterModal = true }) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 20))
                                    .foregroundColor(.black)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 130) // Push content down so it starts below the header
                    
                    // Category Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            let displayCategories = ["BREAKKIE", "LUNCH", "BRUNCH", "VEG"]
                            ForEach(displayCategories, id: \.self) { category in
                                let isSelected = (selectedFilter.uppercased() == category) || (selectedFilter == "Breakfast" && category == "BREAKKIE")
                                Text(category)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(isSelected ? .white : .gray)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(isSelected ? Color.black : Color.white)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(isSelected ? Color.clear : Color(hex: "E5E5E5"), lineWidth: 1)
                                            )
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring()) {
                                            if category == "BREAKKIE" { selectedFilter = "Breakfast" }
                                            else { selectedFilter = category.capitalized }
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Main Featured Cards (Horizontal Scroll)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(filteredRestaurants.prefix(5)) { restaurant in
                                NewFeaturedCard(
                                    restaurant: restaurant,
                                    isFavorite: favoriteRestaurantIds.contains(restaurant.id),
                                    onFavoriteToggle: {
                                        toggleFavorite(restaurant.id)
                                    },
                                    onTap: {
                                        selectedRestaurantForDetail = restaurant
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Nearby Section (2-Column Grid / 1x2 Style)
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Nearby")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.black)
                            Spacer()
                            Text("view all >")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.gray)
                                .onTapGesture { showExploreAll = true }
                        }
                        .padding(.horizontal, 24)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(filteredRestaurants.dropFirst(5)) { restaurant in
                                GridRestaurantCard(
                                    restaurant: restaurant,
                                    isFavorite: favoriteRestaurantIds.contains(restaurant.id),
                                    onFavoriteToggle: {
                                        toggleFavorite(restaurant.id)
                                    },
                                    onTap: {
                                        selectedRestaurantForDetail = restaurant
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 24)
                    
                    Spacer().frame(height: 120) // padding for tab bar
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // MARK: - Sticky Top Bar (Floating on top)
            VStack(spacing: 0) {
                HStack {
                    Button(action: { 
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showNotifications = true 
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.black)
                            
                            if hasNotifications {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 10, height: 10)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    .offset(x: 2, y: -2)
                            }
                        }
                        .padding(8)
                    }
                    
                    Spacer()
                    
                    Text("CURATED")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button(action: { 
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showFilterModal = true 
                        }
                    }) {
                        VStack(alignment: .trailing, spacing: 5) {
                            Capsule().fill(Color.black).frame(width: 14, height: 2.5)
                            Capsule().fill(Color.black).frame(width: 24, height: 2.5)
                        }
                        .padding(8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 40)
                .background(
                    ZStack {
                        // 1. Material Layer with Multi-stop Parabolic Mask
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .mask(
                                LinearGradient(
                                    stops: [
                                        .init(color: .black, location: 0),
                                        .init(color: .black, location: 0.4),
                                        .init(color: .black.opacity(0.8), location: 0.6),
                                        .init(color: .black.opacity(0.3), location: 0.85),
                                        .init(color: .clear, location: 1.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        // 2. Subtle Tint Layer (Creamy Glass)
                        Rectangle()
                            .fill(Color(hex: "FDFBF7").opacity(0.4))
                            .mask(
                                LinearGradient(
                                    colors: [.black, .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                )
                .shadow(color: Color.black.opacity(0.03), radius: 20, x: 0, y: 10)
            }
            .zIndex(100)
        }
    }
    
    // MARK: - Carousel Logic Helpers
    // dragOffset moved to top
    
    // Calculate relative position (-1, 0, 1) handling circular wrap
    func getRelativePosition(index: Int, screenWidth: CGFloat) -> CGFloat {
        let count = 5
        let current = carouselIndex
        
        // Simple distance
        var diff = CGFloat(index - current)
        
        // Circular Wrapping Logic
        // If diff is too large (meaning we are wrapping around), adjust it
        if diff < -CGFloat(count) / 2 {
            diff += CGFloat(count)
        } else if diff > CGFloat(count) / 2 {
            diff -= CGFloat(count)
        }
        
        return diff
    }
    
    // Removed old getScale/getRotation as they are integrated in view
    
    // Helper extension for clean gradient
    var transparent: Color { Color.black.opacity(0.0) }
    
    // Helper
    func getUserName() -> String {
        // 1. Try to get the registered username from Firestore profile
        if let user = authManager.currentUser, !user.username.isEmpty {
            return user.username
        }
        
        // 2. Fallback to Email Prefix if username is missing but session exists
        if let email = authManager.userSession?.email, !email.isEmpty {
            let prefix = email.components(separatedBy: "@").first ?? ""
            if !prefix.isEmpty {
                // Capitalize the first letter for a nicer greeting
                return prefix.prefix(1).uppercased() + prefix.dropFirst().lowercased()
            }
        }
        
        // 3. Final default
        return "Traveler"
    }
    
    // Tab Icons Helper
    func getTabIcon(_ index: Int, isSelected: Bool) -> String {
        switch index {
        case 0: return "" // Custom drawn
        case 1: return isSelected ? "map.fill" : "map"
        case 2: return isSelected ? "heart.fill" : "heart"
        case 3: return isSelected ? "person.fill" : "person"
        default: return "circle"
        }
    }
}

// MARK: - Custom Shapes
struct HouseRoof: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// Bouncy Button Style for Micro-animations
struct BouncyButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Components

// Notification Item View
struct NotificationItemView: View {
    let notification: HomeView.Notification
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.05))
                    .frame(width: 48, height: 48)
                
                Image(systemName: notification.type.rawValue)
                    .font(.system(size: 18, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(Color.black)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(notification.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.black)
                    
                    Spacer()
                    
                    Text(notification.time)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.black.opacity(0.3))
                }
                
                Text(notification.message)
                    .font(.system(size: 14))
                    .lineSpacing(2)
                    .foregroundColor(.black.opacity(0.6))
                    .lineLimit(3)
                
                if !notification.isRead {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 6, height: 6)
                        Text("New")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(notification.isRead ? Color.white : Color(hex: "FDFBF7"))
        )
        .shadow(color: .black.opacity(notification.isRead ? 0.03 : 0.06), radius: 15, x: 0, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
    }
}

// TabBar Button Component
struct TabBarButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                    .scaleEffect(isSelected ? 1.15 : 1.0)
                
                // Active Indicator Dot
                Circle()
                    .fill(isSelected ? Color.white : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.black : Color.white)
                )
                .shadow(color: Color.black.opacity(isSelected ? 0.15 : 0.08), radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 4 : 2)
                .foregroundColor(isSelected ? .white : Color.black)
        }
        .buttonStyle(BouncyButton()) // Micro-animation
        .animation(.spring(response: 0.22, dampingFraction: 0.85), value: isSelected)
    }
}

func getIcon(for title: String) -> String {
    switch title {
    case "Breakfast": return "cup.and.saucer.fill"
    case "Brunch": return "fork.knife"
    case "Dinner": return "wineglass.fill"
    case "Coffee": return "mug.fill"
    case "Japanese": return "fish.fill"
    case "Indonesian": return "flame.fill"
    case "Western": return "fork.knife.circle.fill"
    case "Thai": return "leaf.fill"
    case "Vietnamese": return "drop.fill" // Soup/Pho
    default: return "star.fill"
    }
}

// Category Content View for Swipeable Categories
struct CategoryContentView: View {
    let category: String
    let restaurants: [Restaurant]
    let favoriteIds: Set<UUID>
    let onToggleFavorite: (UUID) -> Void
    @Binding var selectedRestaurantForDetail: Restaurant?
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                if restaurants.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No places found for \(category)")
                            .foregroundColor(.gray)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(restaurants) { restaurant in
                        MoreRestaurantRow(
                            restaurant: restaurant,
                            isFavorite: favoriteIds.contains(restaurant.id),
                            onFavoriteToggle: {
                                onToggleFavorite(restaurant.id)
                            },
                            onTap: {
                                selectedRestaurantForDetail = restaurant
                            }
                        )
                        .padding(.horizontal, 24)
                    }
                }
            }
            .padding(.top, 8)
        }
    }
}

// Compact restaurant row for "More Places" section
struct MoreRestaurantRow: View {
    let restaurant: Restaurant
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Image
            AsyncImage(url: URL(string: restaurant.imageURL)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if phase.error != nil {
                    ZStack {
                        Color.gray.opacity(0.1)
                        Image(systemName: "photo")
                            .foregroundColor(.gray.opacity(0.3))
                    }
                } else {
                    ZStack {
                        Color.gray.opacity(0.1)
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .frame(width: 100, height: 110)
            .clipped()
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text(restaurant.name)
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(.black)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button(action: onFavoriteToggle) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                            .foregroundColor(isFavorite ? .red : .black.opacity(0.1))
                    }
                    .highPriorityGesture(TapGesture().onEnded { onFavoriteToggle() })
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Text(restaurant.location)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                HStack(spacing: 8) {
                    Text(restaurant.priceRange)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black.opacity(0.8))
                    
                    Text("•")
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text(restaurant.status)
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(restaurant.status == "OPEN" ? .green : (restaurant.status == "BUSY" ? .orange : .red))
                }
                
                // Amenities
                HStack(spacing: 6) {
                    ForEach(restaurant.amenities.prefix(4), id: \.self) { amenity in
                        Image(systemName: getAmenityIcon(amenity))
                            .font(.system(size: 10))
                            .foregroundColor(.black.opacity(0.4))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.06), radius: 15, x: 0, y: 8)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
    
    private func getAmenityIcon(_ name: String) -> String {
        switch name.lowercased() {
        case "wifi": return "wifi"
        case "ac": return "snowflake"
        case "pet": return "pawprint.fill"
        case "outdoor": return "sun.max.fill"
        case "parking": return "car.fill"
        case "halal": return "checkmark.seal.fill"
        case "bar": return "wineglass.fill"
        case "smoking": return "smoke.fill"
        default: return "star.fill"
        }
    }
}



// Custom Shape for Header
struct CustomCorner: Shape {
    var corners: UIRectCorner
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Continuous per-corner rounded shape
struct ContinuousCorner: Shape {
    var corners: UIRectCorner
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        // Use UIBezierPath for specific corners, then smooth with continuous corner radius by overlaying a RoundedRectangle mask
        let bezier = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        var path = Path(bezier.cgPath)
        // Apply slight smoothing by intersecting with a continuous rounded rectangle on the full rect
        let smooth = RoundedRectangle(cornerRadius: radius, style: .continuous).path(in: rect)
        path.addPath(smooth)
        return path
    }
}

// Extension for Placeholder in ZStack
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}



// MARK: - Navigation Views

struct ExploreMapView: View {
    let allRestaurants: [Restaurant]
    @Binding var selectedRestaurantForDetail: Restaurant?
    @Binding var showNotifications: Bool
    let hasNotifications: Bool
    
    // iOS 17+ Map State
    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -8.6500, longitude: 115.1300), // Canggu Center
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    ))
    @State private var selectedRestaurant: Restaurant? = nil
    
    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $position) {
                ForEach(allRestaurants) { restaurant in
                    Annotation(restaurant.name, coordinate: CLLocationCoordinate2D(latitude: restaurant.latitude, longitude: restaurant.longitude)) {
                        Button(action: {
                            withAnimation(.spring()) {
                                selectedRestaurant = restaurant
                                position = .region(MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(latitude: restaurant.latitude, longitude: restaurant.longitude),
                                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                                ))
                            }
                        }) {
                            VStack(spacing: 0) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title)
                                    .foregroundColor(Color.black)
                                    .background(Circle().fill(.white))
                                    .scaleEffect(selectedRestaurant == restaurant ? 1.5 : 1.0) // Scale up when selected
                                
                                if selectedRestaurant != restaurant {
                                    Text(restaurant.name)
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(4)
                                        .background(Color.white.opacity(0.8))
                                        .cornerRadius(4)
                                        .offset(y: 5)
                                }
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .onTapGesture {
                withAnimation {
                    selectedRestaurant = nil
                }
            }
            
            // Fixed Branding Header (Mirroring Home)
            VStack(spacing: 0) {
                HStack {
                    Button(action: { 
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showNotifications = true 
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.black)
                            
                            if hasNotifications {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 10, height: 10)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    .offset(x: 2, y: -2)
                            }
                        }
                        .padding(8)
                    }
                    
                    Spacer()
                    
                    Text("CURATED")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button(action: { /* menu action */ }) {
                        VStack(alignment: .trailing, spacing: 5) {
                            Capsule().fill(Color.black).frame(width: 14, height: 2.5)
                            Capsule().fill(Color.black).frame(width: 24, height: 2.5)
                        }
                        .padding(8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 30)
                .background(
                    ZStack {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .mask(
                                LinearGradient(
                                    stops: [
                                        .init(color: .black, location: 0),
                                        .init(color: .black, location: 0.4),
                                        .init(color: .black.opacity(0.8), location: 0.6),
                                        .init(color: .black.opacity(0.3), location: 0.85),
                                        .init(color: .clear, location: 1.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .ignoresSafeArea()
                )
            }
            
            // Header Overlay for Card
            VStack {
                Spacer()
                
                // Selected Restaurant Info Card
                if let restaurant = selectedRestaurant {
                    VStack(spacing: 0) {
                        MoreRestaurantRow(
                            restaurant: restaurant,
                            isFavorite: false,
                            onFavoriteToggle: {},
                            onTap: {
                                selectedRestaurantForDetail = restaurant
                            }
                        )
                        
                        Button(action: {
                            openInAppleMaps(restaurant: restaurant)
                        }) {
                            HStack {
                                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                Text("Open in Apple Maps")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.black)
                            .cornerRadius(12)
                            .padding(.top, 12)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 20)
                    .padding(24)
                    .padding(.bottom, 90) // Clear tab bar with extra breathing room
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
    
    private func openInAppleMaps(restaurant: Restaurant) {
        let location = CLLocation(latitude: restaurant.latitude, longitude: restaurant.longitude)
        let mapItem = MKMapItem(location: location, address: nil)
        mapItem.name = restaurant.name
        
        // Attempt to open in Apple Maps app
        let success = mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
        
        // Fallback to URL scheme if MKMapItem fails
        if !success {
            let encodedName = restaurant.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let urlString = "http://maps.apple.com/?q=\(encodedName)&ll=\(restaurant.latitude),\(restaurant.longitude)"
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }
    }
}

struct FavoritesView: View {
    let allRestaurants: [Restaurant]
    let favoriteIds: Set<UUID>
    let onToggleFavorite: (UUID) -> Void
    @Binding var selectedRestaurantForDetail: Restaurant?
    
    var favoritedList: [Restaurant] {
        allRestaurants.filter { favoriteIds.contains($0.id) }
    }
    
    // Grid columns for a more balanced look
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .center, spacing: 6) {
                Text("Your Favorites")
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundColor(Color.black)
                
                Text("\(favoritedList.count) curated gems saved")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.black.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 70)
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
            
            if favoritedList.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "heart.slash.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.2))
                    Text("No favorites yet.\nStart discover your gems!")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        ForEach(favoritedList) { restaurant in
                            FavoriteRestaurantCard(
                                restaurant: restaurant,
                                isFavorite: true,
                                onFavoriteToggle: {
                                    onToggleFavorite(restaurant.id)
                                },
                                onTap: {
                                    selectedRestaurantForDetail = restaurant
                                }
                            )
                            .frame(maxWidth: 340) // Balanced width for a centered look
                        }
                    }
                    .frame(maxWidth: .infinity) // Ensures the VStack is centered
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120)
                }
            }
        }
        .background(Color(hex: "FDFBF7").ignoresSafeArea())
    }
}


struct FavoriteRestaurantCard: View {
    let restaurant: Restaurant
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                // Image with a fixed height and proper clipping
                AsyncImage(url: URL(string: restaurant.imageURL)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if phase.error != nil {
                        ZStack {
                            Color.gray.opacity(0.05)
                            Image(systemName: "photo")
                                .foregroundColor(.gray.opacity(0.2))
                        }
                    } else {
                        ZStack {
                            Color.gray.opacity(0.05)
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .onTapGesture { onTap() }
                
                // Favorite Button (Compact Glass)
                Button(action: onFavoriteToggle) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
                }
                .padding(8)
                .highPriorityGesture(TapGesture().onEnded { onFavoriteToggle() })
                
                // Rating Overlay
                HStack(spacing: 3) {
                    Text(String(format: "%.1f", restaurant.rating))
                        .font(.system(size: 10, weight: .bold))
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.black.opacity(0.6))
                .clipShape(Capsule())
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
            
            // Info Section (Fixed heights to ensure alignment)
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .frame(height: 20) // Ensure consistent text baseline
                
                HStack(spacing: 3) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                    Text(restaurant.location)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 0) // Push status to bottom
                
                HStack {
                    Text(restaurant.priceRange)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black.opacity(0.5))
                    
                    Spacer()
                    
                    Text(restaurant.status)
                        .font(.system(size: 7, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(restaurant.status == "OPEN" ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                        .foregroundColor(restaurant.status == "OPEN" ? .green : .orange)
                        .clipShape(Capsule())
                }
            }
            .padding(.top, 10)
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .padding(8)
        .frame(height: 240) // FIXED TOTAL HEIGHT for perfect alignment
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.03), radius: 12, x: 0, y: 6)
        .onTapGesture { onTap() }
    }
}





struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showEditProfile = false
    @State private var showNotifications = false
    @State private var showSecurity = false
    @State private var showHelp = false
    @State private var showPayment = false
    @State private var showBookings = false
    @State private var showPreferences = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header with Avatar
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.black, Color.black.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 110, height: 110)
                            .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 6) {
                        Text(authManager.currentUser?.username ?? "Traveler")
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .foregroundColor(Color.black)
                        
                        Text(authManager.userSession?.email ?? "traveler@bali.com")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        // Member since badge
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                            Text("Member since 2024")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(Color.black.opacity(0.6))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.1))
                        .clipShape(Capsule())
                        .padding(.top, 4)
                    }
                }
                .padding(.top, 80)
                .padding(.bottom, 10)
                
                // Stats Cards
                HStack(spacing: 12) {
                    ProfileStatCard(icon: "heart.fill", value: "12", label: "Favorites", color: .red)
                    ProfileStatCard(icon: "map.fill", value: "8", label: "Visited", color: Color.black)
                    ProfileStatCard(icon: "star.fill", value: "24", label: "Reviews", color: .orange)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                
                // Account Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Account")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    
                VStack(spacing: 0) {
                        ProfileMenuRow(
                            icon: "person.circle.fill",
                            title: "Edit Profile",
                            subtitle: "Update your personal information",
                            iconColor: Color.black
                        ) {
                            showEditProfile = true
                        }
                        
                        ProfileMenuRow(
                            icon: "creditcard.fill",
                            title: "Payment Methods",
                            subtitle: "Manage your payment options",
                            iconColor: .blue
                        ) {
                            showPayment = true
                        }
                        
                        ProfileMenuRow(
                            icon: "calendar.badge.clock",
                            title: "My Bookings",
                            subtitle: "View your reservations",
                            iconColor: .green
                        ) {
                            showBookings = true
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(20)
                    .padding(.horizontal, 24)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                }
                .padding(.bottom, 8)
                
                // Preferences Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Preferences")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 24)
                    
                    VStack(spacing: 0) {
                        ProfileMenuRow(
                            icon: "slider.horizontal.3",
                            title: "Preferences",
                            subtitle: "Dietary & dining preferences",
                            iconColor: .purple
                        ) {
                            showPreferences = true
                        }
                        
                        ProfileMenuRow(
                            icon: "bell.fill",
                            title: "Notifications",
                            subtitle: "Manage notification settings",
                            iconColor: .orange
                        ) {
                            showNotifications = true
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(20)
                    .padding(.horizontal, 24)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                }
                .padding(.bottom, 8)
                
                // Support Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Support")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 24)
                    
                    VStack(spacing: 0) {
                        ProfileMenuRow(
                            icon: "shield.fill",
                            title: "Security",
                            subtitle: "Password & privacy settings",
                            iconColor: .indigo
                        ) {
                            showSecurity = true
                        }
                        
                        ProfileMenuRow(
                            icon: "questionmark.circle.fill",
                            title: "Help & Support",
                            subtitle: "FAQs and contact support",
                            iconColor: .cyan
                        ) {
                            showHelp = true
                        }
                        
                        ProfileMenuRow(
                            icon: "info.circle.fill",
                            title: "About",
                            subtitle: "App version 1.0.0",
                            iconColor: .gray,
                            showChevron: false
                        )
                    }
                    .background(Color.white)
                    .cornerRadius(20)
                    .padding(.horizontal, 24)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                }
                .padding(.bottom, 8)
                
                // Sign Out Button
                    Button(action: {
                        authManager.signOut()
                    }) {
                        HStack {
                        Spacer()
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                            Text("Sign Out")
                            .font(.system(size: 16, weight: .semibold))
                            Spacer()
                        }
                    .foregroundColor(.red)
                    .padding(.vertical, 16)
                .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .red.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 100)
            }
        }
        .background(Color(hex: "FDFBF7").ignoresSafeArea())
    }
}

struct ProfileStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color.black)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct ProfileMenuRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var iconColor: Color = Color.black
    var showChevron: Bool = true
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            action?()
        }) {
        HStack(spacing: 15) {
                // Icon with background
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
            Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
            Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.black)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                
            Spacer()
                
                if showChevron {
            Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(PlainButtonStyle())
        
        if showChevron {
            Divider()
                .padding(.leading, 70)
        }
    }
}

// MARK: - Utilities

struct ExploreAllView: View {
    @Binding var isPresented: Bool
    let allRestaurants: [Restaurant]
    let favoriteIds: Set<UUID>
    let onToggleFavorite: (UUID) -> Void
    @Binding var selectedRestaurantForDetail: Restaurant?
    
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    let filters = ["All", "Breakfast", "Brunch", "Dinner", "Coffee", "Bar", "Japanese", "Indonesian", "Western", "Thai"]
    
    var filteredResults: [Restaurant] {
        allRestaurants.filter { restaurant in
            let matchesSearch = searchText.isEmpty || restaurant.name.localizedCaseInsensitiveContains(searchText) || restaurant.location.localizedCaseInsensitiveContains(searchText)
            let matchesFilter = selectedFilter == "All" || restaurant.categories.contains(selectedFilter)
            return matchesSearch && matchesFilter
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { 
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isPresented = false 
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 48, height: 48)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                }
                
                Spacer()
                
                Text("Explore")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(.black)
                
                Spacer()
                
                Color.clear.frame(width: 48, height: 48)
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, 20)
            .background(Color(hex: "FDFBF7"))
            
            // Search Bar (Liquid Glass Style)
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.black.opacity(0.2))
                    .font(.system(size: 18, weight: .bold))
                TextField("Search restaurants or area...", text: $searchText)
                    .foregroundColor(.black)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 24)
            
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(filters, id: \.self) { filter in
                        FilterChip(title: filter, isSelected: selectedFilter == filter) {
                            withAnimation {
                                selectedFilter = filter
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            
            // Results List
            ScrollView {
                VStack(spacing: 24) {
                    if filteredResults.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "magnifyingglass.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.3))
                            Text("No results found")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 100)
                    } else {
                        ForEach(filteredResults) { restaurant in
                            MoreRestaurantRow(
                                restaurant: restaurant,
                                isFavorite: favoriteIds.contains(restaurant.id),
                                onFavoriteToggle: {
                                    onToggleFavorite(restaurant.id)
                                },
                                onTap: {
                                    selectedRestaurantForDetail = restaurant
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
            }
        }
        .background(Color(hex: "FDFBF7").ignoresSafeArea())
    }
}

struct NewFeaturedCard: View {
    let restaurant: Restaurant
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: restaurant.imageURL)) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Color.gray.opacity(0.2)
                }
            }
            .frame(width: 280, height: 260)
            .clipped()
            .onTapGesture {
                onTap()
            }
            
            LinearGradient(colors: [.black.opacity(0.8), .clear], startPoint: .bottom, endPoint: .center)
                .allowsHitTesting(false)
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(restaurant.name)
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 10))
                        Text(restaurant.location)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                .onTapGesture {
                    onTap()
                }
                
                Spacer()
                
                Button(action: onFavoriteToggle) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(isFavorite ? .red : .white)
                }
            }
            .padding(16)
        }
        .frame(width: 280, height: 260)
        .cornerRadius(24)
    }
}

struct NewNearbyCard: View {
    let restaurant: Restaurant
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: restaurant.imageURL)) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Color.gray.opacity(0.2)
                }
            }
            .frame(width: 60, height: 60)
            .cornerRadius(12)
            .onTapGesture { onTap() }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundColor(.black)
                
                Text(restaurant.priceRange)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.gray)
            }
            .onTapGesture { onTap() }
            
            Spacer(minLength: 20)
            
            Button(action: onFavoriteToggle) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 18))
                    .foregroundColor(isFavorite ? .red : .black)
            }
        }
        .padding(12)
        .frame(width: 200)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct GridRestaurantCard: View {
    let restaurant: Restaurant
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image Section
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: restaurant.imageURL)) { phase in
                    if let image = phase.image {
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                    } else {
                        Rectangle().fill(Color.gray.opacity(0.1))
                    }
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .clipped()
                
                Button(action: onFavoriteToggle) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 14))
                        .foregroundColor(isFavorite ? .red : .white)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .padding(10)
            }
            
            // Info Section
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Text(restaurant.location)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                HStack {
                    Text(restaurant.priceRange)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black.opacity(0.8))
                    Spacer()
                    Text(restaurant.status)
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(restaurant.status == "OPEN" ? .green : .orange)
                }
                .padding(.top, 4)
            }
            .padding(12)
            .background(Color.white)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        .onTapGesture { onTap() }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthManager.shared)
        .environmentObject(LanguageManager.shared)
}


// RestaurantCard updated with continuous corners for main card

struct RestaurantCard: View {
    let restaurant: Restaurant
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Image Section
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: restaurant.imageURL)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if phase.error != nil {
                        ZStack {
                            Color.gray.opacity(0.1)
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.3))
                        }
                    } else {
                        ZStack {
                            Color.gray.opacity(0.1)
                            ProgressView()
                        }
                    }
                }
                .frame(height: 220)
                .clipped()
                
                // Favorite Button
                Button(action: onFavoriteToggle) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(isFavorite ? .red : .white)
                        .padding(12)
                        .background(BlurView(style: .systemThinMaterialDark).clipShape(Circle()))
                        .padding(16)
                }
                .highPriorityGesture(TapGesture().onEnded { onFavoriteToggle() })
                
                // Rating Overlay
                HStack(spacing: 4) {
                    Text(String(format: "%.1f", restaurant.rating))
                        .font(.system(size: 14, weight: .bold))
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(BlurView(style: .systemThinMaterialDark).clipShape(Capsule()))
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
            .overlay(alignment: .topLeading) {
                Text(restaurant.status)
                    .font(.system(size: 14, weight: .bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(hex: "28C76F"))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(16)
            }
            
            // Bottom Info Section (Navy Background)
            VStack(alignment: .leading, spacing: 12) {
                // Reserve Tag
                Text("RESERVE")
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: "D81B60"))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                HStack(alignment: .firstTextBaseline) {
                    Text(restaurant.name)
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(restaurant.priceRange)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Text(restaurant.location)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.5))
                
                // Bottom Line Decor
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 1)
                    .padding(.top, 10)
            }
            .padding(20)
            .background(Color.black)
        }
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}
