import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: BabyHealthStore
    @State private var name = ""
    @State private var dateOfBirth = Calendar.current.date(byAdding: .month, value: -18, to: Date()) ?? Date()
    @State private var gender: BabyGender = .girl
    @State private var bloodType = ""

    private let bloodTypes = ["", "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.appPrimary.opacity(0.14))
                                .frame(width: 92, height: 92)
                            Image(systemName: "heart.text.square.fill")
                                .font(.system(size: 38, weight: .semibold))
                                .foregroundStyle(Color.appPrimary)
                        }

                        Text("Baby Health Tracker")
                            .font(.rounded(30, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text("Create the first baby profile. The app will preload sample health data and the Vietnam EPI vaccination schedule so you can try every screen right away.")
                            .font(.rounded(15))
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    VStack(spacing: 16) {
                        TextField("Baby name", text: $name)
                            .textContentType(.givenName)
                            .padding(14)
                            .background(Color.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        DatePicker("Date of birth", selection: $dateOfBirth, displayedComponents: .date)
                            .font(.rounded(15, weight: .semibold))

                        Picker("Gender", selection: $gender) {
                            ForEach(BabyGender.allCases) { gender in
                                Text(gender.title).tag(gender)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker("Blood type", selection: $bloodType) {
                            Text("Not set").tag("")
                            ForEach(bloodTypes.filter { !$0.isEmpty }, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }

                        Button {
                            store.addProfile(name: name.isEmpty ? "Baby" : name, dateOfBirth: dateOfBirth, gender: gender, bloodType: bloodType)
                        } label: {
                            Label("Create Profile", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.appPrimary)
                        .controlSize(.large)
                    }
                    .padding(20)
                    .appCard()
                }
                .padding(24)
            }
        }
    }
}
