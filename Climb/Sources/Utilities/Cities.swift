import Foundation

/// Region data containing all US States, DC, US Territories, and Canadian Provinces & Territories
struct City: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let lat: Double
    let lng: Double
}

/// Comprehensive list of Regions (States, Territories, and Provinces)
let CITIES: [City] = [
    // --- District of Columbia & US States ---
    City(name: "Washington, D.C.", lat: 38.9072, lng: -77.0369),
    City(name: "Alabama", lat: 32.3182, lng: -86.9023),
    City(name: "Alaska", lat: 63.5887, lng: -154.4931),
    City(name: "Arizona", lat: 34.0489, lng: -111.0937),
    City(name: "Arkansas", lat: 35.2010, lng: -91.8318),
    City(name: "California", lat: 36.7783, lng: -119.4179),
    City(name: "Colorado", lat: 39.5501, lng: -105.7821),
    City(name: "Connecticut", lat: 41.6032, lng: -73.0877),
    City(name: "Delaware", lat: 38.9108, lng: -75.5277),
    City(name: "Florida", lat: 27.6648, lng: -81.5158),
    City(name: "Georgia", lat: 32.1656, lng: -82.9001),
    City(name: "Hawaii", lat: 19.8968, lng: -155.5828),
    City(name: "Idaho", lat: 44.0682, lng: -114.7420),
    City(name: "Illinois", lat: 40.6331, lng: -89.3985),
    City(name: "Indiana", lat: 40.2672, lng: -86.1349),
    City(name: "Iowa", lat: 41.8780, lng: -93.0977),
    City(name: "Kansas", lat: 39.0119, lng: -98.4842),
    City(name: "Kentucky", lat: 37.8393, lng: -84.2700),
    City(name: "Louisiana", lat: 30.9843, lng: -91.9623),
    City(name: "Maine", lat: 45.2538, lng: -69.4455),
    City(name: "Maryland", lat: 39.0458, lng: -76.6413),
    City(name: "Massachusetts", lat: 42.4072, lng: -71.3824),
    City(name: "Michigan", lat: 44.3148, lng: -85.6024),
    City(name: "Minnesota", lat: 46.7296, lng: -94.6859),
    City(name: "Mississippi", lat: 32.3547, lng: -89.3985),
    City(name: "Missouri", lat: 37.9643, lng: -91.8318),
    City(name: "Montana", lat: 46.8797, lng: -110.3626),
    City(name: "Nebraska", lat: 41.4925, lng: -99.9018),
    City(name: "Nevada", lat: 38.8026, lng: -116.4194),
    City(name: "New Hampshire", lat: 43.1939, lng: -71.5724),
    City(name: "New Jersey", lat: 40.0583, lng: -74.4057),
    City(name: "New Mexico", lat: 34.5199, lng: -105.8701),
    City(name: "New York", lat: 40.7128, lng: -74.0060),
    City(name: "North Carolina", lat: 35.7596, lng: -79.0193),
    City(name: "North Dakota", lat: 47.5515, lng: -101.0020),
    City(name: "Ohio", lat: 40.4173, lng: -82.9071),
    City(name: "Oklahoma", lat: 35.4676, lng: -97.5164),
    City(name: "Oregon", lat: 43.8041, lng: -120.5542),
    City(name: "Pennsylvania", lat: 41.2033, lng: -77.1945),
    City(name: "Rhode Island", lat: 41.5801, lng: -71.4774),
    City(name: "South Carolina", lat: 33.8361, lng: -81.1637),
    City(name: "South Dakota", lat: 44.3683, lng: -100.3510),
    City(name: "Tennessee", lat: 35.5175, lng: -86.5804),
    City(name: "Texas", lat: 31.9686, lng: -99.9018),
    City(name: "Utah", lat: 39.3210, lng: -111.0937),
    City(name: "Vermont", lat: 44.5588, lng: -72.5778),
    City(name: "Virginia", lat: 37.4316, lng: -78.6569),
    City(name: "Washington", lat: 47.7511, lng: -120.7401),
    City(name: "West Virginia", lat: 38.5976, lng: -80.4549),
    City(name: "Wisconsin", lat: 43.7844, lng: -88.7879),
    City(name: "Wyoming", lat: 43.0759, lng: -107.2903),

    // --- US Territories ---
    City(name: "Puerto Rico", lat: 18.2208, lng: -66.5901),
    City(name: "Guam", lat: 13.4443, lng: 144.7937),
    City(name: "U.S. Virgin Islands", lat: 18.3358, lng: -64.8963),
    City(name: "American Samoa", lat: -14.2710, lng: -170.1322),
    City(name: "Northern Mariana Islands", lat: 15.0979, lng: 145.6739),

    // --- Canadian Provinces & Territories ---
    City(name: "Ontario", lat: 51.2538, lng: -85.3232),
    City(name: "Quebec", lat: 52.9399, lng: -73.5491),
    City(name: "British Columbia", lat: 53.7267, lng: -127.6476),
    City(name: "Alberta", lat: 53.9333, lng: -116.5765),
    City(name: "Manitoba", lat: 53.7609, lng: -98.8139),
    City(name: "Saskatchewan", lat: 52.9399, lng: -106.4509),
    City(name: "Nova Scotia", lat: 44.6820, lng: -63.7443),
    City(name: "New Brunswick", lat: 46.5653, lng: -66.4619),
    City(name: "Newfoundland and Labrador", lat: 53.1355, lng: -57.6604),
    City(name: "Prince Edward Island", lat: 46.5107, lng: -63.4168),
    City(name: "Northwest Territories", lat: 64.8255, lng: -124.8457),
    City(name: "Nunavut", lat: 70.2998, lng: -83.1076),
    City(name: "Yukon", lat: 64.2823, lng: -135.0000)
]
