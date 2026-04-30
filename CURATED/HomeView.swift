import SwiftUI
import FirebaseAuth
import Combine
import MapKit
import CoreLocation

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var languageManager: LanguageManager
    
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
    @State private var favoriteRestaurantIds: Set<UUID> = []
    
    // Transition for filter switching
    @State private var filterTransition: AnyTransition = .opacity
    
    // Notification logic
    @State private var unreadCount: Int = 3
    
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    // Data Models
    struct CarouselItem: Hashable {
        let title: String
        let image: String
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
        let latitude: Double // Added for map
        let longitude: Double // Added for map
    }

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
    let allRestaurants = [
        Restaurant(name: "Red Dragon Ramen", location: "Jl. Dewi Sri, Legian", priceRange: "50k - 120k", status: "OPEN", imageURL: "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=800&q=80", categories: ["Japanese", "Dinner"], amenities: ["ac", "wifi"], latitude: -8.7032, longitude: 115.1786),
        Restaurant(name: "Copenhagen Canggu", location: "Jl. Canggu Padang Linjong", priceRange: "25k - 150k", status: "OPEN", imageURL: "https://images.unsplash.com/photo-1600093463592-8e36ae95ef56?auto=format&fit=crop&w=800&q=80", categories: ["Breakfast", "Brunch", "Coffee", "Western"], amenities: ["ac", "wifi", "pet", "outdoor"], latitude: -8.6480, longitude: 115.1310),
        Restaurant(name: "Crate Cafe", location: "Jl. Canggu Padang Linjong", priceRange: "35k - 80k", status: "BUSY", imageURL: "https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=800&q=80", categories: ["Breakfast", "Brunch", "Coffee", "Western"], amenities: ["wifi", "outdoor", "parking"], latitude: -8.6492, longitude: 115.1320),
        Restaurant(name: "Ulekan", location: "Berawa", priceRange: "80k - 200k", status: "OPEN", imageURL: "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=800&q=80", categories: ["Indonesian", "Dinner"], amenities: ["ac", "wifi", "parking", "halal"], latitude: -8.6620, longitude: 115.1432),
        Restaurant(name: "Monsieur Spoon", location: "Jl. Pantai Batu Bolong", priceRange: "30k - 120k", status: "OPEN", imageURL: "https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?auto=format&fit=crop&w=800&q=80", categories: ["Breakfast", "Coffee", "Western"], amenities: ["ac", "wifi", "pet"], latitude: -8.6515, longitude: 115.1278),
        Restaurant(name: "Kynd Community", location: "Seminyak", priceRange: "80k - 200k", status: "OPEN", imageURL: "https://images.unsplash.com/photo-1493770348161-369560ae357d?auto=format&fit=crop&w=800&q=80", categories: ["Breakfast", "Brunch", "Western"], amenities: ["ac", "wifi", "outdoor", "vegan"], latitude: -8.6740, longitude: 115.1560),
        Restaurant(name: "Penny Lane", location: "Jl. Munduk Catu", priceRange: "80k - 250k", status: "BUSY", imageURL: "https://images.unsplash.com/photo-1559339352-11d035aa65de?auto=format&fit=crop&w=800&q=80", categories: ["Brunch", "Bar", "Dinner", "Western"], amenities: ["ac", "smoking", "bar", "parking"], latitude: -8.6530, longitude: 115.1265),
        Restaurant(name: "Motel Mexicola", location: "Seminyak", priceRange: "100k - 350k", status: "OPEN", imageURL: "https://images.unsplash.com/photo-1560624052-449f5ddf0c78?auto=format&fit=crop&w=800&q=80", categories: ["Bar", "Dinner", "Western"], amenities: ["ac", "bar", "outdoor", "parking"], latitude: -8.6800, longitude: 115.1550),
        Restaurant(name: "Ji Restaurant", location: "Canggu", priceRange: "150k - 500k", status: "OPEN", imageURL: "https://images.unsplash.com/photo-1580822184713-fc5400e7fe10?auto=format&fit=crop&w=800&q=80", categories: ["Japanese", "Dinner", "Bar"], amenities: ["ac", "bar", "outdoor", "pet"], latitude: -8.6522, longitude: 115.1255),
        Restaurant(name: "Potato Head", location: "Seminyak", priceRange: "150k - 600k", status: "OPEN", imageURL: "https://images.unsplash.com/photo-1571939228382-b2f2b585ce15?auto=format&fit=crop&w=800&q=80", categories: ["Bar", "Western", "Dinner"], amenities: ["ac", "bar", "outdoor", "parking"], latitude: -8.6815, longitude: 115.1512),
        Restaurant(name: "Finns Beach Club", location: "Berawa", priceRange: "200k - 800k", status: "BUSY", imageURL: "https://images.unsplash.com/photo-1540541338287-41700207dee6?auto=format&fit=crop&w=800&q=80", categories: ["Bar", "Western"], amenities: ["bar", "outdoor", "parking", "wifi"], latitude: -8.6635, longitude: 115.1402)
    ]
    
    let carouselItems = [
        CarouselItem(title: "Copenhagen Canggu", image: "https://images.unsplash.com/photo-1600093463592-8e36ae95ef56?auto=format&fit=crop&w=800&q=80"),
        CarouselItem(title: "Red Dragon Ramen", image: "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=800&q=80"),
        CarouselItem(title: "Kopi Kenangan", image: "https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=800&q=80")
    ]
    
    var filteredRestaurants: [Restaurant] {
        if selectedFilter == "All" {
            return allRestaurants
        }
        return allRestaurants.filter { $0.categories.contains(selectedFilter) }
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
    }
    
    @State private var scrollOffset: CGFloat = 0
    @State private var isScrollingDown: Bool = false
    @State private var lastScrollOffset: CGFloat = 0
    @State private var headerHiddenProgress: CGFloat = 0 // 0 = fully shown, 1 = fully hidden
    

    
    var body: some View {
        ZStack {
            // Background color
            Color(hex: "FBFCFE").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Navigation Hub
                ZStack {
                    Group {
                        switch selectedTab {
                        case 0:
                            homeContent
                        case 1:
                            ExploreMapView(allRestaurants: allRestaurants)
                        case 2:
                            FavoritesView(allRestaurants: allRestaurants, favoriteIds: favoriteRestaurantIds) { id in
                                toggleFavorite(id)
                            }
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
            .fullScreenCover(isPresented: $showExploreAll) {
                ExploreAllView(allRestaurants: allRestaurants, favoriteIds: favoriteRestaurantIds) { id in
                    toggleFavorite(id)
                }
            }
            
            // MARK: - Notification Drawer Overlay (Slide-In)
            ZStack(alignment: .trailing) {
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
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notifications")
                                .font(.system(size: 28, weight: .bold, design: .serif))
                                .foregroundColor(Color(hex: "0f2c59"))
                            
                            Text("You have \(dummyNotifications.filter { !$0.isRead }.count) unread messages")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            // mark all action
                        }) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "0f2c59").opacity(0.4))
                        }
                    }
                    .padding(.top, 60)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Newest")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(hex: "0f2c59").opacity(0.5))
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
                .frame(width: UIScreen.main.bounds.width * 0.8)
                .padding(.trailing, 100) // Add buffer for bounce overshoot
                .frame(maxHeight: .infinity)
                .background(Color(hex: "FBFCFE"))
                .clipShape(CustomCorner(corners: [.topLeft, .bottomLeft], radius: 35))
                .shadow(color: .black.opacity(0.15), radius: 15, x: -5, y: 0)
                .offset(x: showNotifications ? 100 : UIScreen.main.bounds.width * 0.8 + 150) // Offset logic handling buffer
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
                        .foregroundColor(Color(hex: "0f2c59"))
                    
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
            
            // MARK: - Floating Tab Bar (Telegram/iOS style interaction)
            VStack {
                Spacer()
                
                GeometryReader { geo in
                    let hPadding: CGFloat = 24
                    let barHeight: CGFloat = 68
                    let totalWidth = geo.size.width - (hPadding * 2)
                    let tabWidth = totalWidth / 4
                    
                    ZStack {
                        // 1. White Background Container (Statik & Luas)
                        Capsule()
                            .fill(Color.white)
                            .frame(height: barHeight)
                            .shadow(color: Color(hex: "0f2c59").opacity(0.12), radius: 15, x: 0, y: 8)
                        
                        // 2. Sliding Pill Indicator (Elegant Capsule)
                        Capsule()
                            .fill(Color(hex: "0f2c59"))
                            .frame(
                                width: isTabBarPressed ? tabWidth - 8 : tabWidth - 20,
                                height: isTabBarPressed ? 58 : 44
                            )
                            .shadow(color: Color(hex: "0f2c59").opacity(isTabBarPressed ? 0.3 : 0), radius: 10, x: 0, y: 5)
                            // Align perfectly under icons with math cleanup
                            .offset(x: -totalWidth/2 + tabWidth/2 + CGFloat(selectedTab) * tabWidth)
                            .animation(.spring(response: 0.32, dampingFraction: 0.75), value: selectedTab)
                            .animation(.spring(response: 0.22, dampingFraction: 0.65), value: isTabBarPressed)
                        
                        // 3. Tab Icons (Senter Presisi)
                        HStack(spacing: 0) {
                            ForEach(0..<4, id: \.self) { index in
                                let isSelected = selectedTab == index
                                Image(systemName: getTabIcon(index, isSelected: isSelected))
                                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                                    .foregroundColor(isSelected ? .white : Color(hex: "0f2c59").opacity(0.35))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: barHeight)
                            }
                        }
                    }
                    .frame(height: barHeight)
                    .padding(.horizontal, hPadding)
                    .contentShape(Capsule())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if !isTabBarPressed {
                                    withAnimation(.spring(response: 0.18, dampingFraction: 0.6)) {
                                        isTabBarPressed = true
                                    }
                                }
                                let x = value.location.x
                                let index = Int(floor(x / tabWidth))
                                let clamped = min(max(index, 0), 3)
                                
                                if clamped != selectedTab {
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
                                        selectedTab = clamped
                                    }
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                                    isTabBarPressed = false
                                }
                            }
                    )
                }
                .frame(height: 74)
                .padding(.bottom, 24)
                .offset(y: isKeyboardVisible ? 150 : 0)
                .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isKeyboardVisible)
            }
            .zIndex(50)
        }
        .ignoresSafeArea(edges: .top)
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
        VStack(spacing: 0) {
            headerView
                .zIndex(1)
            
            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .top) {
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: ScrollOffsetKey.self, value: geo.frame(in: .named("scrollArea")).minY)
                    }
                    .frame(height: 0)
                    
                    VStack(spacing: 24) {
                        // Add spacing to prevent content from being covered by header
                        Spacer().frame(height: 80)
                        
                        featuredCarousel
                        
                        // Curated Section with Swipeable Categories
                        VStack(alignment: .leading, spacing: 16) {
                            Spacer().frame(height: 20)
                            HStack {
                                Text("Curated for You")
                                    .font(.system(size: 22, weight: .bold, design: .serif))
                                    .foregroundColor(Color(hex: "0f2c59"))
                                Spacer()
                                Button("View all >") {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        showExploreAll = true
                                    }
                                }
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(hex: "0f2c59").opacity(0.6))
                            }
                            .padding(.horizontal, 24)
                            
                            // Main Category Chips (Breakfast, Brunch, Lunch, Dinner)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(mainCategories, id: \.self) { category in
                                        FilterChip(title: category, isSelected: mainCategories[currentCategoryIndex] == category) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                if let index = mainCategories.firstIndex(of: category) {
                                                    currentCategoryIndex = index
                                                    selectedFilter = category
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            
                            // Swipeable Content Area (only for main categories)
                            if mainCategories.contains(selectedFilter) {
                                GeometryReader { geometry in
                                    HStack(spacing: 0) {
                                        ForEach(Array(mainCategories.enumerated()), id: \.element) { index, category in
                                            CategoryContentView(
                                                category: category,
                                                restaurants: getRestaurantsForCategory(category),
                                                favoriteIds: favoriteRestaurantIds,
                                                onToggleFavorite: toggleFavorite
                                            )
                                            .frame(width: geometry.size.width)
                                        }
                                    }
                                    .offset(x: -CGFloat(currentCategoryIndex) * geometry.size.width + categoryDragOffset)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentCategoryIndex)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                categoryDragOffset = value.translation.width
                                            }
                                            .onEnded { value in
                                                let threshold: CGFloat = 50
                                                if value.translation.width > threshold && currentCategoryIndex > 0 {
                                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                        currentCategoryIndex -= 1
                                                        selectedFilter = mainCategories[currentCategoryIndex]
                                                    }
                                                } else if value.translation.width < -threshold && currentCategoryIndex < mainCategories.count - 1 {
                                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                        currentCategoryIndex += 1
                                                        selectedFilter = mainCategories[currentCategoryIndex]
                                                    }
                                                }
                                                categoryDragOffset = 0
                                            }
                                    )
                                }
                                .frame(height: 400) // Adjust based on content
                                .padding(.bottom, 40)
                            } else {
                                // Fallback for non-main categories (All, Coffee, Bar, etc.)
                            ZStack {
                                LazyVStack(spacing: 12) {
                                    if filteredRestaurants.isEmpty {
                                        VStack(spacing: 12) {
                                                Image(systemName: "fork.knife.circle")
                                                    .font(.system(size: 40))
                                                    .foregroundColor(.gray.opacity(0.5))
                                                Text("No places found for \(selectedFilter)")
                                                    .foregroundColor(.gray)
                                            }
                                            .frame(height: 200)
                                            .frame(maxWidth: .infinity)
                                    } else {
                                        ForEach(filteredRestaurants) { restaurant in
                                                MoreRestaurantRow(
                                                    restaurant: restaurant,
                                                    isFavorite: favoriteRestaurantIds.contains(restaurant.id)
                                                ) {
                                                toggleFavorite(restaurant.id)
                                            }
                                            .padding(.horizontal, 24)
                                        }
                                    }
                                }
                                .id(selectedFilter)
                                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                            }
                            .padding(.bottom, 40)
                            }
                        }
                        
                        Spacer().frame(height: 30)
                        
                        // Recommendations Footer
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Popular Destinations")
                                .font(.system(size: 22, weight: .bold, design: .serif))
                                .foregroundColor(Color(hex: "0f2c59"))
                                .padding(.horizontal, 24)
                                .padding(.top, 40)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(allRestaurants.prefix(4)) { restaurant in
                                        MoreRestaurantRow(restaurant: restaurant, isFavorite: favoriteRestaurantIds.contains(restaurant.id)) {
                                            toggleFavorite(restaurant.id)
                                        }
                                        .frame(width: 310) // Slightly wider for comfort
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        .padding(.bottom, 150)
                    }
                    .padding(.top, 20)
                }
            }
            .coordinateSpace(name: "scrollArea")
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                scrollOffset = value
                // value is negative when scrolling down
                let maxHideDistance: CGFloat = 140 // how much to scroll before fully hidden
                headerHiddenProgress = min(1, max(0, -value / maxHideDistance))
            }
        }
    }
    
    // MARK: - Header View
    var headerView: some View {
        // Scroll Logic
        // We want the main header content (Navy BG, Greeting, Search) to scroll up with the content.
        // We translate it upwards based on scrollOffset (clamped to 0 so it doesn't move down).
        let scrollY = min(scrollOffset, 0) // Negative as we scroll down
        
        return ZStack(alignment: .top) {
            
            // 1. Dynamic/Scrolling Part (Navy Box + Greeting + Search)
            ZStack(alignment: .top) {
                // Background
                Color(hex: "0f2c59")
                    .frame(height: 280) // Fixed height initial
                    .clipShape(CustomCorner(corners: [.bottomLeft, .bottomRight], radius: 40))
                    .shadow(color: Color(hex: "0f2c59").opacity(0.3), radius: 20, x: 0, y: 10)
                
                VStack(spacing: 0) {
                    Spacer().frame(height: 120) // Spacer for the Logo area (increased from 100 to 120)
                    
                    // Greeting + Bell aligned
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: -2) {
                            Text("Hey, \(getUserName())")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Ready to Explore?")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Spacer()
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                showNotifications = true
                                hasNotifications = false
                            }
                        }) {
                            ZStack(alignment: .topTrailing) {
                                // Bell Icon (No circle background)
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 26))
                                    .foregroundColor(.white)
                                
                                // Red Notification Dot (cutting/biting into the bell - OVERLAP effect)
                                if hasNotifications {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 11, height: 11)
                                        .overlay(
                                            Circle()
                                                .stroke(Color(hex: "0f2c59"), lineWidth: 3)
                                        )
                                        .offset(x: 0, y: 1)
                                }
                            }
                        }
                        .buttonStyle(BouncyButton())
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 24)
                    
                    // Search Bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.6))
                        
                        TextField("Find your craving...", text: $searchText)
                            .placeholder(when: searchText.isEmpty) {
                                Text("Find your craving...")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .foregroundColor(.white)
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                showFilterModal = true
                            }
                        }) {
                            Image(systemName: "line.3.horizontal.decrease")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .buttonStyle(BouncyButton())
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.15))
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 30)
            }
            .offset(y: scrollY)
            .opacity(1 - headerHiddenProgress)
            .offset(y: headerHiddenProgress * -80) // stronger slide up
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: headerHiddenProgress)
            
            // 2. Static Part (Pinned Logo & Bell)
            // Stays at top regardless of scrollY.
            HStack {
                Spacer()
                Text("CURATED")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .tracking(3)
                    .foregroundColor(headerHiddenProgress > 0.5 ? .white : Color(hex: "0f2c59"))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        Capsule()
                            .fill(headerHiddenProgress > 0.5 ? Color(hex: "0f2c59") : Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                    .scaleEffect(1 - headerHiddenProgress * 0.04)
                    .animation(.spring(response: 0.28, dampingFraction: 0.85), value: headerHiddenProgress)
                Spacer()
            }
            .padding(.top, 60)
        }
        .frame(height: max(140, 280 + scrollY), alignment: .top) // Clip frame with min height
        .padding(.bottom, -140) // Allow overlap into next view - increased to push content down more
    }
    
    // MARK: - Featured Carousel (Cover Flow Style)
    var featuredCarousel: some View {
        ZStack {
            GeometryReader { fullGeo in
                let screenWidth = fullGeo.size.width
                let cardWidth = screenWidth * 0.65 // Smaller Card (65% of screen)
                let spacing = screenWidth * 0.05 // Spacing/Visual gap
                
                // Use the first 5 restaurants for the carousel
                let featuredRestaurants = Array(allRestaurants.prefix(5))
                
                ZStack {
                    ForEach(0..<featuredRestaurants.count, id: \.self) { index in
                        let relativePos = getRelativePosition(index: index, screenWidth: screenWidth) // We need to update getRelativePosition to use featuredRestaurants.count if we change the count, but for now let's just use what we have or adapt carefully.
                        // Actually, getRelativePosition tracks `carouselIndex`. We need to ensure logic holds.
                        
                        let isCenter = relativePos == 0
                        let restaurant = featuredRestaurants[index]
                        
                        // Image Card Container
                        ZStack(alignment: .bottomLeading) {
                            // Background Image with proper clipping
                            AsyncImage(url: URL(string: restaurant.imageURL)) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: cardWidth, height: 200)
                                        .clipped() // Clip overflow BEFORE shape
                                } else {
                                    Color.gray.opacity(0.3)
                                        .frame(width: cardWidth, height: 200)
                                }
                            }
                            .frame(width: cardWidth, height: 200)
                            
                            // Gradient Overlay
                            LinearGradient(
                                colors: [.black.opacity(0.8), .black.opacity(0.0)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                            
                            // Heart Button
                            VStack {
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        toggleFavorite(restaurant.id)
                                    }) {
                                        Image(systemName: favoriteRestaurantIds.contains(restaurant.id) ? "heart.fill" : "heart")
                                            .font(.system(size: 20))
                                            .foregroundColor(favoriteRestaurantIds.contains(restaurant.id) ? .red : .white)
                                            .padding(8)
                                            .background(Circle().fill(.black.opacity(0.4)))
                                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                    }
                                    .padding(12)
                                }
                                Spacer()
                            }
                            
                            // Text Info at Bottom
                            VStack(alignment: .leading, spacing: 4) {
                                Text(restaurant.name)
                                    .font(.system(size: 20, weight: .bold, design: .serif))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                HStack {
                                    Text(restaurant.location)
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Spacer()
                                    
                                    Text("Explore >")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.white.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .opacity(isCenter ? 1 : 0)
                            .animation(.easeOut(duration: 0.2), value: isCenter)
                        }
                        .frame(width: cardWidth, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(
                            color: Color(hex: "0f2c59").opacity(isCenter ? 0.3 : 0.1),
                            radius: isCenter ? 15 : 5,
                            x: 0,
                            y: isCenter ? 8 : 4
                        )
                        .opacity(isCenter ? 1.0 : 0.4)
                        .scaleEffect(1.0) // No scaling
                        .offset(x: relativePos * (cardWidth + spacing)) // Standard linear spacing
                        .offset(x: dragOffset) // Manual Drag
                        .zIndex(isCenter ? 2 : 1) // Center on top
                    }
                }
                .offset(x: screenWidth / 2 - cardWidth / 2) // Center the whole stack
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.width
                            
                            // Calculate drag progress
                            // ... existing drag logic ...
                        }
                        .onEnded { value in
                            // ... existing drag end logic ...
                            let threshold = cardWidth / 2
                            var newIndex = carouselIndex
                            
                            if value.translation.width < -threshold {
                                newIndex += 1
                            } else if value.translation.width > threshold {
                                newIndex -= 1
                            }
                            
                            // Normalize index
                            let count = 5 // Hardcoded for featured restaurants
                            if newIndex < 0 { newIndex = count - 1 }
                            if newIndex >= count { newIndex = 0 }
                            
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                carouselIndex = newIndex
                                dragOffset = 0
                            }
                        }
                )
            }
            .frame(height: 240) // Reduced height
            
            // Navigation Arrows Overlay
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        carouselIndex = (carouselIndex - 1 + 5) % 5
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Circle().fill(Color(hex: "0f2c59").opacity(0.8)))
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                }
                .padding(.leading, 16)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        carouselIndex = (carouselIndex + 1) % 5
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Circle().fill(Color(hex: "0f2c59").opacity(0.8)))
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                }
                .padding(.trailing, 16)
            }
            
            // Page Indicator (Moved here)
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { index in
                        if index == carouselIndex {
                            Capsule()
                                .fill(Color(hex: "0f2c59")) // Navy Blue
                                .frame(width: 24, height: 6)
                                .shadow(color: .white.opacity(0.3), radius: 2)
                        } else {
                            Circle()
                                .fill(Color(hex: "0f2c59").opacity(0.4)) // Navy Blue opacity
                                .frame(width: 6, height: 6)
                        }
                    }
                }
                .padding(.bottom, 5)
                .offset(y: 10) // Reduced offset
            }
        }
        .onReceive(timer) { _ in
            // Only auto-scroll if not dragging
            if dragOffset == 0 {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    carouselIndex = (carouselIndex + 1) % 5
                }
            }
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
        case 0: return isSelected ? "house.fill" : "house"
        case 1: return isSelected ? "location.north.fill" : "location.north"
        case 2: return isSelected ? "heart.fill" : "heart"
        case 3: return isSelected ? "person.fill" : "person"
        default: return "circle"
        }
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
        HStack(alignment: .top, spacing: 14) {
            // Icon
            Image(systemName: notification.type.rawValue)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "0f2c59"))
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color(hex: "0f2c59").opacity(0.1))
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(notification.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "0f2c59"))
                    
                    Spacer()
                    
                    Text(notification.time)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Text(notification.message)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                if !notification.isRead {
                    Circle()
                        .fill(Color(hex: "0f2c59"))
                        .frame(width: 8, height: 8)
                        .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(notification.isRead ? Color.white : Color(hex: "0f2c59").opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: "0f2c59").opacity(notification.isRead ? 0.1 : 0.15), lineWidth: 1)
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
            HStack(spacing: 8) {
                // Icon could be dynamic based on title
                Image(systemName: getIcon(for: title))
                    .font(.system(size: 14))
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: "0f2c59") : Color.white)
            )
            .shadow(color: Color.black.opacity(isSelected ? 0.15 : 0.08), radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 4 : 2)
            .foregroundColor(isSelected ? .white : Color(hex: "0f2c59"))
        }
        .buttonStyle(BouncyButton()) // Micro-animation
        .animation(.spring(response: 0.22, dampingFraction: 0.85), value: isSelected)
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
}

// Category Content View for Swipeable Categories
struct CategoryContentView: View {
    let category: String
    let restaurants: [HomeView.Restaurant]
    let favoriteIds: Set<UUID>
    let onToggleFavorite: (UUID) -> Void
    
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
                            isFavorite: favoriteIds.contains(restaurant.id)
                        ) {
                            onToggleFavorite(restaurant.id)
                        }
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
    let restaurant: HomeView.Restaurant
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // Image
            AsyncImage(url: URL(string: restaurant.imageURL)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.gray.opacity(0.2)
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(ContinuousCorner(corners: [.topRight, .bottomRight], radius: 14))
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(restaurant.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "0f2c59"))
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(restaurant.location)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                HStack(spacing: 8) {
                    Text(restaurant.priceRange)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "0f2c59").opacity(0.7))
                    
                    Text("•")
                        .foregroundColor(.gray)
                    
                    Text(restaurant.status)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(restaurant.status == "OPEN" ? .green : (restaurant.status == "BUSY" ? .orange : .red))
                }
                
                // Amenities
                HStack(spacing: 8) {
                    ForEach(restaurant.amenities, id: \.self) { amenity in
                        Image(systemName: getAmenityIcon(amenity))
                            .font(.system(size: 10)) // Small, unobtrusive
                            .foregroundColor(Color(hex: "0f2c59").opacity(0.5))
                    }
                }
            }
            
            Spacer()
            
            // Favorite Button
            Button(action: onFavoriteToggle) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 18))
                    .foregroundColor(isFavorite ? .red : .gray.opacity(0.5))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white)
                    )
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.05), radius: 5)
            }
            .buttonStyle(BouncyButton())
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // Helper function for amenity icons (already in file, keeping it for local use if needed elsewhere)
    func getAmenityIcon(_ amenity: String) -> String {
        switch amenity.lowercased() {
        case "ac": return "snowflake"
        case "wifi": return "wifi"
        case "parking": return "car.fill"
        case "vegan": return "leaf.fill"
        case "pet friendly": return "pawprint.fill"
        case "outdoor": return "sun.max.fill"
        case "pool": return "figure.pool.swim"
        default: return "star.fill" // Fallback
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
    let allRestaurants: [HomeView.Restaurant]
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -8.6500, longitude: 115.1300), // Canggu Center
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedRestaurant: HomeView.Restaurant? = nil
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, annotationItems: allRestaurants) { restaurant in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: restaurant.latitude, longitude: restaurant.longitude)) {
                    Button(action: {
                        withAnimation(.spring()) {
                            selectedRestaurant = restaurant
                            region.center = CLLocationCoordinate2D(latitude: restaurant.latitude, longitude: restaurant.longitude)
                        }
                    }) {
                        VStack(spacing: 0) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(Color(hex: "0f2c59"))
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
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation {
                    selectedRestaurant = nil
                }
            }
            
            // Header Overlay
            VStack {
                HStack {
                    Spacer()
                    Text("CURATED")
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .tracking(4)
                        .foregroundColor(Color(hex: "0f2c59"))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(
                            Capsule() // Full rounded
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .padding(.top, 60)
                    Spacer()
                }
                Spacer()
                
                // Selected Restaurant Info Card
                if let restaurant = selectedRestaurant {
                    MoreRestaurantRow(restaurant: restaurant, isFavorite: false, onFavoriteToggle: {}) // Simplified for map view, just info
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(radius: 20)
                        .padding(24)
                        .padding(.bottom, 60) // Clear tab bar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
}

struct FavoritesView: View {
    let allRestaurants: [HomeView.Restaurant]
    let favoriteIds: Set<UUID>
    let onToggleFavorite: (UUID) -> Void
    
    var favoritedList: [HomeView.Restaurant] {
        allRestaurants.filter { favoriteIds.contains($0.id) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Your Favorites")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundColor(Color(hex: "0f2c59"))
                .padding(.top, 60)
                .padding(.horizontal, 24)
            
            if favoritedList.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "heart.slash.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.gray.opacity(0.2))
                    Text("No favorites yet.\nStart discover your gems!")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(favoritedList) { restaurant in
                            MoreRestaurantRow(restaurant: restaurant, isFavorite: true) {
                                onToggleFavorite(restaurant.id)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120)
                }
            }
        }
        .background(Color(hex: "FBFCFE").ignoresSafeArea())
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
                                    colors: [Color(hex: "0f2c59"), Color(hex: "0f2c59").opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 110, height: 110)
                            .shadow(color: Color(hex: "0f2c59").opacity(0.3), radius: 15, x: 0, y: 8)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 6) {
                        Text(authManager.currentUser?.username ?? "Traveler")
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .foregroundColor(Color(hex: "0f2c59"))
                        
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
                        .foregroundColor(Color(hex: "0f2c59").opacity(0.6))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "0f2c59").opacity(0.1))
                        .clipShape(Capsule())
                        .padding(.top, 4)
                    }
                }
                .padding(.top, 80)
                .padding(.bottom, 10)
                
                // Stats Cards
                HStack(spacing: 12) {
                    ProfileStatCard(icon: "heart.fill", value: "12", label: "Favorites", color: .red)
                    ProfileStatCard(icon: "map.fill", value: "8", label: "Visited", color: Color(hex: "0f2c59"))
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
                            iconColor: Color(hex: "0f2c59")
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
        .background(Color(hex: "FBFCFE").ignoresSafeArea())
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
                .foregroundColor(Color(hex: "0f2c59"))
            
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
    var iconColor: Color = Color(hex: "0f2c59")
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
                        .foregroundColor(Color(hex: "0f2c59"))
                    
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
    @Environment(\.dismiss) var dismiss
    let allRestaurants: [HomeView.Restaurant]
    let favoriteIds: Set<UUID>
    let onToggleFavorite: (UUID) -> Void
    
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    let filters = ["All", "Breakfast", "Brunch", "Dinner", "Coffee", "Bar", "Japanese", "Indonesian", "Western", "Thai"]
    
    var filteredResults: [HomeView.Restaurant] {
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
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "0f2c59"))
                        .padding(12)
                        .background(Circle().fill(Color.white).shadow(radius: 2))
                }
                
                Spacer()
                
                Text("Explore Bali")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(Color(hex: "0f2c59"))
                
                Spacer()
                
                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, 20)
            .background(Color(hex: "FBFCFE"))
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search restaurants or area...", text: $searchText)
                    .foregroundColor(Color(hex: "0f2c59"))
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
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
                            MoreRestaurantRow(restaurant: restaurant, isFavorite: favoriteIds.contains(restaurant.id)) {
                                onToggleFavorite(restaurant.id)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
            }
        }
        .background(Color(hex: "FBFCFE").ignoresSafeArea())
    }
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthManager.shared)
        .environmentObject(LanguageManager.shared)
}


// RestaurantCard updated with continuous corners for main card

struct RestaurantCard: View {
    let restaurant: HomeView.Restaurant
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
                    } else {
                        Rectangle().fill(Color.gray.opacity(0.1))
                    }
                }
                .frame(height: 220)
                .clipped()
                
                // Favorite Button Overlay
                Button(action: onFavoriteToggle) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(isFavorite ? .red : .white)
                        .padding(12)
                        .background(BlurView(style: .systemThinMaterialDark).clipShape(Circle()))
                        .padding(16)
                }
                
                // Status Tag (e.g., OPEN) - Top Left (Aligned within another ZStack helper if needed, but let's just use topLeading overlay)
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
                        .font(.system(size: 22, weight: .bold))
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
            .background(Color(hex: "0f2c59"))
        }
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}
