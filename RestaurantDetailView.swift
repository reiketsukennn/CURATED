import SwiftUI
import MapKit

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    @Environment(\.presentationMode) var presentationMode
    
    // Map State for this specific restaurant
    @State private var position: MapCameraPosition
    @State private var showAllReviews = false
    @State private var showWriteReview = false
    @State private var showBookings = false
    @State private var showAllPhotos = false
    @State private var isFavorite = false
    
    @EnvironmentObject var reviewStore: ReviewStore
    
    private var displayedReviews: [Review] {
        reviewStore.getReviews(for: restaurant)
    }
    
    // Screen Width Helper
    private var screenWidth: CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene ?? scenes.first as? UIWindowScene
        return windowScene?.screen.bounds.width ?? 393
    }
    
    init(restaurant: Restaurant) {
        self.restaurant = restaurant
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: restaurant.latitude, longitude: restaurant.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )))
    }
    
    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // 1. Hero Image Header
                    ZStack(alignment: .topLeading) {
                        AsyncImage(url: URL(string: restaurant.imageURL)) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: screenWidth, height: 440)
                                    .clipped()
                            } else if phase.error != nil {
                                ZStack {
                                    Color.gray.opacity(0.1)
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.3))
                                }
                                .frame(width: screenWidth, height: 440)
                            } else {
                                ZStack {
                                    Color.gray.opacity(0.1)
                                    ProgressView()
                                }
                                .frame(width: screenWidth, height: 440)
                            }
                        }
                        
                        // Price Overlay (Cafe Style)
                        VStack {
                            Spacer()
                            HStack {
                                Text(restaurant.priceRange)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(.black.opacity(0.6))
                                    .cornerRadius(12)
                                Spacer()
                            }
                            .padding(24)
                        }
                        
                        HStack {
                            // Back Button
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(.black.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                // Share Button
                                Button(action: {
                                    // Placeholder for share action
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(.black.opacity(0.3))
                                        .clipShape(Circle())
                                }
                                
                                // Favorite Button
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                        isFavorite.toggle()
                                    }
                                }) {
                                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(isFavorite ? .red : .white)
                                        .padding(12)
                                        .background(.black.opacity(0.3))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.top, 60)
                        .padding(.horizontal, 20)
                    }
                    .frame(width: screenWidth)
                    .frame(height: 440)
                    
                    // 2. Title Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center, spacing: 8) {
                            Text(restaurant.categories.first?.uppercased() ?? "CAFE")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.gray)
                                .tracking(2)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 12))
                                Text("4.8")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.yellow.opacity(0.1))
                            .cornerRadius(20)
                        }
                        
                        Text(restaurant.name)
                            .font(.system(size: 34, weight: .bold, design: .serif))
                            .foregroundColor(.black)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                            Text(restaurant.location)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // 3. Photos (Thumbnails)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Photos")
                                .font(.system(size: 18, weight: .bold))
                            Spacer()
                            Text("See all")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 24)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(restaurant.galleryImages, id: \.self) { imgURL in
                                    AsyncImage(url: URL(string: imgURL)) { image in
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Color.gray.opacity(0.2)
                                    }
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    // 4. Details & Vibe
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Ambiance & Details")
                            .font(.system(size: 18, weight: .bold))
                            .padding(.horizontal, 24)
                        
                        HStack(spacing: 0) {
                            DetailItem(icon: "star.fill", value: restaurant.specialty, label: "Specialty")
                            Spacer()
                            DetailItem(icon: "clock.fill", value: restaurant.status, label: "Status")
                            Spacer()
                            DetailItem(icon: "sparkles", value: restaurant.vibe, label: "Vibe")
                        }
                        .padding(.horizontal, 32)
                        
                        Text(restaurant.description)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineSpacing(4)
                            .padding(.horizontal, 24)
                    }
                    
                    // 5. Amenities
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Cafe Amenities")
                            .font(.system(size: 18, weight: .bold))
                            .padding(.horizontal, 24)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(restaurant.amenities, id: \.self) { amenity in
                                HStack(spacing: 12) {
                                    Image(systemName: getAmenityIcon(amenity))
                                        .foregroundColor(.gray)
                                        .frame(width: 24)
                                    Text(amenity.capitalized)
                                        .font(.system(size: 14, weight: .medium))
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                    
                    // 6. Location Map
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Location")
                                .font(.system(size: 18, weight: .bold))
                            Spacer()
                            Button(action: openInAppleMaps) {
                                Text("Open in Maps")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Map(position: $position) {
                            Annotation(restaurant.name, coordinate: CLLocationCoordinate2D(latitude: restaurant.latitude, longitude: restaurant.longitude)) {
                                Button(action: openInAppleMaps) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.black)
                                        .background(Circle().fill(.white))
                                }
                            }
                        }
                        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.horizontal, 24)
                        .onTapGesture {
                            openInAppleMaps()
                        }
                    }
                    
                        HStack {
                            Text("Reviews (\(displayedReviews.count))")
                                .font(.system(size: 18, weight: .bold))
                            Spacer()
                            Button(action: {
                                withAnimation(.spring()) {
                                    showAllReviews = true
                                }
                            }) {
                                Text("See all")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                if displayedReviews.isEmpty {
                                    Text("No reviews yet.")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 24)
                                } else {
                                    ForEach(displayedReviews.prefix(3)) { review in
                                        ReviewCard(
                                            name: review.user,
                                            rating: String(format: "%.1f", review.rating),
                                            text: review.comment,
                                            userImage: review.userImage
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                    .padding(.bottom, 180)
                }
            }
            .background(Color.clear) 
            .ignoresSafeArea()
            .sheet(isPresented: $showAllReviews) {
                AllReviewsView(restaurant: restaurant)
            }
            .sheet(isPresented: $showWriteReview) {
                WriteReviewView(restaurant: restaurant)
            }
            
        }
        .background(Color(hex: "FDFBF7").ignoresSafeArea())
        .overlay(
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            }) {
                Text("Reserve a Table")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 280)
                    .frame(height: 56)
                    .background(Color.black)
                    .cornerRadius(28)
            }
            .padding(.bottom, 44), // Adjust line 342 for height only
            alignment: .bottom
        )
    }
    
    func openInAppleMaps() {
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
    
    func getAmenityIcon(_ name: String) -> String {
        switch name.lowercased() {
        case "ac": return "snowflake"
        case "wifi": return "wifi"
        case "pet": return "pawprint.fill"
        case "outdoor": return "leaf.fill"
        case "parking": return "parkingsign"
        default: return "checkmark.circle.fill"
        }
    }
}

struct DetailItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 14, weight: .bold))
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
    }
}

struct ReviewCard: View {
    let name: String
    let rating: String
    let text: String
    let userImage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                AsyncImage(url: URL(string: userImage)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.1))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 14, weight: .bold))
                    Text("Verified Reviewer")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 10))
                    Text(rating)
                        .font(.system(size: 12, weight: .bold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
            }
            
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.black.opacity(0.7))
                .lineSpacing(4)
                .lineLimit(3)
        }
        .padding(16)
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

// MARK: - AllReviewsView

struct AllReviewsView: View {
    let restaurant: Restaurant
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var reviewStore: ReviewStore
    @State private var showWriteReview = false
    
    private var displayedReviews: [Review] {
        reviewStore.getReviews(for: restaurant)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(displayedReviews) { review in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                AsyncImage(url: URL(string: review.userImage)) { image in
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Circle().fill(Color.gray.opacity(0.1))
                                }
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(review.user)
                                        .font(.system(size: 16, weight: .bold))
                                    Text(review.date)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 12))
                                    Text(String(format: "%.1f", review.rating))
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .cornerRadius(10)
                            }
                            
                            Text(review.comment)
                                .font(.system(size: 14))
                                .lineSpacing(6)
                                .foregroundColor(.primary.opacity(0.8))
                            
                            Divider().padding(.top, 8)
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.top, 24)
            }
            .navigationTitle("Customer Reviews")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showWriteReview = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                            Text("Write")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                }
            }
            .sheet(isPresented: $showWriteReview) {
                WriteReviewView(restaurant: restaurant)
            }
        }
    }
}

// MARK: - Write Review View
struct WriteReviewView: View {
    let restaurant: Restaurant
    @Environment(\.dismiss) var dismiss
    @State private var rating: Int = 0
    @State private var comment: String = ""
    @EnvironmentObject var reviewStore: ReviewStore
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header Profile
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.05))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.black.opacity(0.2))
                    }
                    
                    Text("Sharing your experience at")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Text(restaurant.name)
                        .font(.system(size: 20, weight: .bold, design: .serif))
                }
                .padding(.top, 40)
                
                // Star Rating
                VStack(spacing: 16) {
                    Text("How was your visit?")
                        .font(.system(size: 16, weight: .semibold))
                    
                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= rating ? "star.fill" : "star")
                                .font(.system(size: 32))
                                .foregroundColor(index <= rating ? .yellow : .gray.opacity(0.3))
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                        rating = index
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                        }
                    }
                }
                
                // Comment Field
                VStack(alignment: .leading, spacing: 12) {
                    Text("Write your review")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.leading, 4)
                    
                    ZStack(alignment: .topLeading) {
                        if comment.isEmpty {
                            Text("Describe your experience (the food, atmosphere, service)...")
                                .font(.system(size: 15))
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                        }
                        
                        TextEditor(text: $comment)
                            .font(.system(size: 15))
                            .frame(height: 150)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.black.opacity(0.03))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.black.opacity(0.05), lineWidth: 1)
                                    )
                            )
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Submit Button
                Button(action: {
                    isSubmitting = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    
                    // Simulate API Call
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        // Create and add the new review
                        let newReview = Review(
                            user: "Zuan", // Using user's name for demo
                            rating: Double(rating),
                            comment: comment,
                            date: "Just now",
                            userImage: "https://i.pravatar.cc/150?u=zuan"
                        )
                        reviewStore.addReview(newReview, to: restaurant.id)
                        
                        isSubmitting = false
                        dismiss()
                    }
                }) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                                .padding(.trailing, 8)
                        }
                        Text(isSubmitting ? "Posting..." : "Post Review")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(rating == 0 ? Color.gray.opacity(0.3) : Color.black)
                    .cornerRadius(28)
                    .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                }
                .disabled(rating == 0 || isSubmitting)
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                }
            }
        }
    }
}

#Preview {
    RestaurantDetailView(restaurant: Restaurant(
        name: "Copenhagen Canggu",
        location: "Jl. Canggu Padang Linjong",
        priceRange: "25k - 150k",
        status: "OPEN",
        imageURL: "https://images.unsplash.com/photo-1600093463592-8e36ae95ef56?auto=format&fit=crop&w=800&q=80",
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
            Review(user: "Mike Ross", rating: 4.0, comment: "Cozy vibe, good coffee. Can get busy on weekends.", date: "3 days ago", userImage: "https://i.pravatar.cc/150?u=mike")
        ],
        rating: 4.7
    ))
    .environmentObject(ReviewStore())
}
