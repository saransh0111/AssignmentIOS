import SwiftUI
import Foundation

struct LoginScreen: View {
    @State private var userEmail: String = ""
    @State private var emailError: String? = nil
    @State private var navigateToHome = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Full screen black background
                Color.black
                    .ignoresSafeArea(.all)
                
                VStack(alignment: .center, spacing: 32) {
                    Spacer()
                    titleSection
                    CustomTextField(title: "Email", text: $userEmail, placeholder: "Enter your email address")
                    if let error = emailError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    nextSubmitButton
                    Spacer()
                    
                    // Navigation to Home when email is correct
                    NavigationLink(destination: Home(email: userEmail),
                                  isActive: $navigateToHome) {
                        EmptyView()
                    }
                }
                .padding(.horizontal, 32)
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

extension LoginScreen {
    
    private var titleSection: some View {
        VStack(alignment: .center, spacing: 16) {
            Text("Rabbit Invest")
                .font(Font.custom("Lato-Regular", size: 20))
                .foregroundColor(.white)
            
            Text("Login")
                .font(Font.custom("Lato-Regular", size: 36).weight(.semibold))
                .foregroundColor(.white)
        }
    }
    
    struct CustomTextField: View {
        let title: String
        @Binding var text: String
        let placeholder: String

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.custom("Lato-Regular", size: 16))
                    .foregroundColor(.white)
                
                TextField(placeholder, text: $text)
                    .font(.custom("Lato-Regular", size: 16))
                    .foregroundColor(.black)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
            }
        }
    }
    
    private var nextSubmitButton: some View {
        Button(action: {
            if isValidEmail(userEmail) {
                emailError = nil
                navigateToHome = true
            } else {
                emailError = "Please enter a valid email address"
            }
        }) {
            Text("Next")
                .font(.custom("Lato-Bold", size: 20))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
}

struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreen()
    }
}
