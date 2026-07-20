import SwiftUI

/// Searchable city picker matching the web's combobox
struct CityPickerView: View {
    @Binding var selectedCity: City?
    @State private var searchText = ""
    @State private var isExpanded = false

    private var filteredCities: [City] {
        if searchText.isEmpty {
            return CITIES
        }
        return CITIES.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Region")
                .font(ClimbTheme.bodyFont(size: 14))
                .fontWeight(.bold)
                .foregroundColor(ClimbTheme.primaryColor)
                .textCase(.uppercase)
                .tracking(1)
                .padding(.bottom, 8)

            // Search input
            TextField("Type to search city...", text: $searchText, onEditingChanged: { editing in
                isExpanded = editing
            })
            .font(ClimbTheme.bodyFont(size: 16))
            .foregroundColor(ClimbTheme.textMain)
            .padding(12)
            .background(ClimbTheme.bgPrimary)
            .overlay(
                Rectangle()
                    .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
            )
            .onChange(of: searchText) { _, newValue in
                if newValue != selectedCity?.name {
                    isExpanded = true
                }
            }

            // Dropdown
            if isExpanded {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if filteredCities.isEmpty {
                            Text("No cities found")
                                .font(ClimbTheme.bodyFont(size: 15))
                                .foregroundColor(ClimbTheme.textMuted)
                                .padding(10)
                        } else {
                            ForEach(filteredCities) { city in
                                Button(action: {
                                    selectedCity = city
                                    searchText = city.name
                                    isExpanded = false
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                }) {
                                    HStack {
                                        Text(city.name)
                                            .font(ClimbTheme.bodyFont(size: 15))
                                            .foregroundColor(ClimbTheme.textMain)
                                            .fontWeight(selectedCity?.name == city.name ? .bold : .regular)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(selectedCity?.name == city.name ? ClimbTheme.primaryColor : Color.clear)
                                }
                                .buttonStyle(.plain)

                                if city.id != filteredCities.last?.id {
                                    Rectangle()
                                        .fill(ClimbTheme.bgPrimary)
                                        .frame(height: 2)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
                .background(ClimbTheme.bgSecondary)
                .overlay(
                    Rectangle()
                        .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
                )
                .offset(y: -3) // Overlap border like the web
            }
        }
        .onAppear {
            if let city = selectedCity {
                searchText = city.name
            }
        }
        .onChange(of: selectedCity) { _, newCity in
            if let city = newCity, searchText != city.name {
                searchText = city.name
            }
        }
    }
}
