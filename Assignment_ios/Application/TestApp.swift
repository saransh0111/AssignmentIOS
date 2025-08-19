//
//  TestApp.swift
//  Assignment_ios
//
//  Created by Saransh Nirmalkar on 19/08/25.
//
import SwiftUI

@main
struct TestApp: App {
    @AppStorage("signIn") var isSignedIn: Bool = false
    var body: some Scene {
        WindowGroup {
            if isSignedIn{
                Home(email: "test@gmail.com")
            }else{
                LoginScreen()
            }
        }
    }
}
