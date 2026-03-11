import AccessibilitySnapshotPreviews
import SwiftUI

struct CustomContentDemo: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DemoSection(
                title: "Custom Content",
                description: "Additional details via 'More Content' rotor"
            ) {
                VStack(spacing: 12) {
                    productCard(
                        name: "Wireless Headphones",
                        price: "$149.99",
                        rating: 4.5,
                        reviews: 2847,
                        sku: "WH-1000XM5"
                    )

                    productCard(
                        name: "Bluetooth Speaker",
                        price: "$79.99",
                        rating: 4.2,
                        reviews: 1523,
                        sku: "BS-MINI-BLK"
                    )
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Custom Content")
    }

    private func productCard(
        name: String,
        price: String,
        rating: Double,
        reviews: Int,
        sku: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)

            HStack {
                Text(price)
                    .font(.caption)
                    .fontWeight(.semibold)

                Spacer()

                Text("★ \(String(format: "%.1f", rating))")
                    .font(.caption2)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(price)")
        .accessibilityCustomContent("Rating", "\(String(format: "%.1f", rating)) stars from \(reviews) reviews")
        .accessibilityCustomContent("SKU", sku, importance: .high)
    }
}

#Preview {
    CustomContentDemo()
        .accessibilityPreview()
}
