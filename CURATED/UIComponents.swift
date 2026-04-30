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
                    .fill(Color(hex: "0f2c59").opacity(0.3))
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
