import sys
import re

filepath = '/Users/reiketsukennn/Cursor/CURATED/HomeView.swift'

with open(filepath, 'r') as f:
    content = f.read()

# Refine Filter Chips (Add stroke to unselected pills)
old_pill_bg = """                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(isSelected ? Color.black : Color.white)
                                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                    )"""
new_pill_bg = """                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(isSelected ? Color.black : Color.white)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(isSelected ? Color.clear : Color(hex: "E5E5E5"), lineWidth: 1)
                                            )
                                    )"""
content = content.replace(old_pill_bg, new_pill_bg)

# Refine NewFeaturedCard (Bigger cards)
content = content.replace(".frame(width: 240, height: 260)", ".frame(width: 280, height: 300)")

# Refine NewNearbyCard (Use dynamic priceRange instead of hardcoded)
content = content.replace("""Text("25k - 125k") // Mock price since it's in the design""", """Text(restaurant.priceRange)""")

# Fix getTabIcon
old_get_tab_icon = """    func getTabIcon(_ index: Int, isSelected: Bool) -> String {
        switch index {
        case 0: return isSelected ? "house.fill" : "house"
        case 1: return isSelected ? "location.north.fill" : "location.north"
        case 2: return isSelected ? "heart.fill" : "heart"
        case 3: return isSelected ? "person.fill" : "person"
        default: return "circle"
        }
    }"""
new_get_tab_icon = """    func getTabIcon(_ index: Int, isSelected: Bool) -> String {
        switch index {
        case 0: return "house"
        case 1: return "location"
        case 2: return "heart"
        case 3: return "person"
        default: return "circle"
        }
    }"""
content = content.replace(old_get_tab_icon, new_get_tab_icon)

with open(filepath, 'w') as f:
    f.write(content)

print("Refinements applied!")
