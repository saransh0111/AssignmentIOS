import SwiftUI
import Foundation

struct Home: View {
    let email: String
    @State var navigateToLogin: Bool = false
    @State var navigateToFundselection: Bool = false
    @State var navigateToMyFunds: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea(.all)
                
                VStack(alignment: .center) {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Spacer()
                        Text("Welcome Home 👋")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        
                        Text("Logged in as: \(email)")
                            .font(.title3)
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: {
                            navigateToFundselection = true
                        }) {
                            Text("Fund Selection")
                                .font(.custom("Lato-Bold", size: 20))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            navigateToMyFunds = true
                        }) {
                            Text("My Funds")
                                .font(.custom("Lato-Bold", size: 20))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        Spacer()
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        TokenManager.shared.clearTokens()
                        UserDefaults.standard.set(false, forKey: "signIn")
                        navigateToLogin = true
                    }) {
                        Text("Logout")
                            .font(.custom("Lato-Bold", size: 20))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    
                    NavigationLink(destination: LoginScreen(), isActive: $navigateToLogin) {
                        EmptyView()
                    }
                    NavigationLink(destination: FundSelection(), isActive: $navigateToFundselection) {
                        EmptyView()
                    }
                }
                .padding(.horizontal, 32)
            }
        }
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home(email: "saransh0111@gmail.com")
    }
}
