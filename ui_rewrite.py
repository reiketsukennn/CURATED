import sys
import re

filepath = '/Users/reiketsukennn/Cursor/CURATED/HomeView.swift'

with open(filepath, 'r') as f:
    content = f.read()

# Replace Tab Bar
tab_bar_pattern = r'// MARK: - Floating Tab Bar \(Telegram/iOS style interaction\).*?\.zIndex\(50\)'
new_tab_bar = """// MARK: - Floating Tab Bar
            VStack {
                Spacer()
                HStack {
                    ForEach(0..<4, id: \.self) { index in
                        Spacer()
                        Button(action: {
                            withAnimation(.spring()) { selectedTab = index }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: getTabIcon(index, isSelected: selectedTab == index))
                                    .font(.system(size: 24, weight: selectedTab == index ? .semibold : .regular))
                                    .foregroundColor(selectedTab == index ? .white : Color.white.opacity(0.3))
                                
                                if selectedTab == index {
                                    Rectangle()
                                        .fill(Color.white)
                                        .frame(width: 20, height: 3)
                                        .cornerRadius(1.5)
                                } else {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(width: 20, height: 3)
                                }
                            }
                            .frame(height: 60)
                        }
                        Spacer()
                    }
                }
                .padding(.vertical, 10)
                .background(Color.black)
                .cornerRadius(40)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .offset(y: isKeyboardVisible ? 150 : 0)
                .animation(.spring(), value: isKeyboardVisible)
            }
            .zIndex(50)"""

content = re.sub(tab_bar_pattern, new_tab_bar, content, flags=re.DOTALL)

# Replace homeContent & delete headerView & featuredCarousel
# We can find `private var homeContent: some View {` and `// MARK: - Carousel Logic Helpers`
# and replace everything in between.
home_content_pattern = r'private var homeContent: some View \{.*?// MARK: - Carousel Logic Helpers'

new_home_content = """private var homeContent: some View {
        VStack(spacing: 0) {
            // New Clean Header
            VStack(alignment: .leading, spacing: 20) {
                // Top Bar: Bell, Title, Menu
                HStack {
                    Button(action: { showNotifications = true }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.black)
                            
                            if hasNotifications {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Text("CURATED")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gray)
                        .tracking(1)
                    
                    Spacer()
                    
                    Button(action: { /* menu action */ }) {
                        VStack(alignment: .trailing, spacing: 5) {
                            Capsule().fill(Color.black).frame(width: 24, height: 3)
                            Capsule().fill(Color.black).frame(width: 16, height: 3)
                            Capsule().fill(Color.black).frame(width: 24, height: 3)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                
                // Greeting text
                Text("Discover\\ncurated Cafe and Resto!")
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
            .padding(.bottom, 20)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 30) {
                    // Category Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            let displayCategories = ["BREAKKIE", "LUNCH", "BRUNCH", "VEG"]
                            ForEach(displayCategories, id: \\.self) { category in
                                let isSelected = (selectedFilter.uppercased() == category) || (selectedFilter == "Breakfast" && category == "BREAKKIE")
                                Text(category)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(isSelected ? .white : .gray)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(isSelected ? Color.black : Color.white)
                                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
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
                                NewFeaturedCard(restaurant: restaurant, isFavorite: favoriteRestaurantIds.contains(restaurant.id)) {
                                    toggleFavorite(restaurant.id)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Nearby Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Nearby")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.black)
                            Spacer()
                            Text("view all >")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 24)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(allRestaurants.shuffled().prefix(5)) { restaurant in
                                    NewNearbyCard(restaurant: restaurant, isFavorite: favoriteRestaurantIds.contains(restaurant.id)) {
                                        toggleFavorite(restaurant.id)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    Spacer().frame(height: 120) // padding for tab bar
                }
                .padding(.top, 10)
            }
        }
        .background(Color(hex: "FBFCFE").ignoresSafeArea())
    }
    
    // MARK: - Carousel Logic Helpers"""

content = re.sub(home_content_pattern, new_home_content, content, flags=re.DOTALL)

# Add new components before #Preview
components_addition = """struct NewFeaturedCard: View {
    let restaurant: HomeView.Restaurant
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: restaurant.imageURL)) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Color.gray.opacity(0.2)
                }
            }
            .frame(width: 240, height: 260)
            .clipped()
            
            LinearGradient(colors: [.black.opacity(0.8), .clear], startPoint: .bottom, endPoint: .center)
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(restaurant.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 10))
                        Text(restaurant.location)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white.opacity(0.8))
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
        .frame(width: 240, height: 260)
        .cornerRadius(24)
    }
}

struct NewNearbyCard: View {
    let restaurant: HomeView.Restaurant
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    
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
            
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                
                Text("25k - 125k") // Mock price since it's in the design
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.gray)
            }
            
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

#Preview {"""

content = content.replace("#Preview {", components_addition)

with open(filepath, 'w') as f:
    f.write(content)

print("UI Rewrite script completed!")
