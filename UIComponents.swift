import SwiftUI

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct GrowingButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct SocialButton: View {
    let icon: String
    var body: some View {
        Button(action: {}) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                
                if icon == "google" {
                    AsyncImage(url: URL(string: "https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png")) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                    } placeholder: {
                        ProgressView().controlSize(.small)
                    }
                } else if icon == "facebook" {
                    AsyncImage(url: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Facebook_Logo_%282019%29.png/600px-Facebook_Logo_%282019%29.png")) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                            .clipShape(Circle())
                    } placeholder: {
                        ProgressView().controlSize(.small)
                    }
                } else {
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                }
            }
        }
        .buttonStyle(GrowingButton())
    }
}

struct PremiumInputField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var accessory: AnyView? = nil
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.black.opacity(0.4))
                .font(.system(size: 16, weight: .medium))
                .frame(width: 24)
            
            if isSecure {
                SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(.black.opacity(0.2)))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.black)
            } else {
                TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.black.opacity(0.2)))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.black)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            if let accessory = accessory {
                accessory
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

struct InputField<Content: View>: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var accessory: () -> Content
    
    init(icon: String, placeholder: String, text: Binding<String>, isSecure: Bool = false, @ViewBuilder accessory: @escaping () -> Content = { EmptyView() }) {
        self.icon = icon
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.accessory = accessory
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.6))
                .font(.system(size: 16))
                .frame(width: 20)
            
            if isSecure {
                SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.3)).font(.system(size: 14)))
                    .foregroundColor(.white)
            } else {
                TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.3)).font(.system(size: 14)))
                    .foregroundColor(.white)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            accessory()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
        )
    }
}

// Global View Extension for professional shadows
extension View {
    func premiumShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
    
    func softShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    func textStroke() -> some View {
        self.shadow(color: Color.black.opacity(0.3), radius: 2, x: 1, y: 1)
    }
}

struct TermsAndPolicyView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Terms and Conditions")
                        .font(.title2).bold()
                    
                    Text("Welcome to CURATED. By using our service, you agree to follow these terms...")
                        .font(.body)
                    
                    Text("Privacy Policy")
                        .font(.title2).bold()
                    
                    Text("We respect your privacy and handle your data with care...")
                        .font(.body)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Terms & Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
