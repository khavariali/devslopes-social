//
//  ViewController.swift
//  devslopes-social
//
//  Created by Allen on 06/12/2016.
//  Copyright © 2016 IT Emergency Malaysia. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase


class SignInVC: UIViewController, UITextFieldDelegate {
    @IBOutlet var emailField: FancyField!
    @IBOutlet var passwordField: FancyField!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        emailField.delegate = self
        passwordField.delegate = self
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func facebookBtnTapped(_ sender: Any) {
        
        let facebookLogin = FBSDKLoginManager()
        facebookLogin.logIn(withReadPermissions: ["email"], from: self) { (result, error) in
            
            if error != nil {
                
                print("****Reza***: Unable to authenticate with facebook\(error.debugDescription)")
                
            } else if result?.isCancelled == true {
                
                print("****Reza**** User cancled facebook authentication")
                
            } else {
                
                print("****Reza**** Successfully authenticated with facebook")
                let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                self.firebaseAuth(credential)
            }
        }
    }
    
    func firebaseAuth(_ credential: FIRAuthCredential) {
        FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) in
            if error != nil {
                print("****Reza**** Unable authenticate with firebase\(error.debugDescription)")
            } else {
                
                print("****Reza**** Successfully authenticate with firebase")
                
            }
        })
    }
    
    // Disapear keyboard if user touches any area in the app
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    //Dismiss keyboard when you puch return or user push return in they keyboard
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    @IBAction func signInTapped(_ sender: Any) {
        if let email = emailField.text, let password = passwordField.text {
            FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (iser, error) in
                if error == nil {
                    print("***Reza*** email/password User authenticated with firebase")
                } else {
                    FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
                        if error != nil {
                            print("***REZA*** Unable to authenticate with firebase using email/password\(error.debugDescription)")
                            // check for other senarios password lenght and other things... alert
                        } else {
                            print("***REZA*** Successfully authenticated with email/password firebase")
                        }
                    })
                }
            })
        }
    }
}

