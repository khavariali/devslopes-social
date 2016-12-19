//
//  FeedVC.swift
//  devslopes-social
//
//  Created by Allen on 08/12/2016.
//  Copyright © 2016 IT Emergency Malaysia. All rights reserved.
//

import UIKit
import Firebase
import SwiftKeychainWrapper

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var imageAdd: CircleView!
    @IBOutlet var captionField: FancyField!
    
    var posts = [Post]()
    var imagePicker: UIImagePickerController!
    static var imageCache: NSCache<NSString, UIImage> = NSCache()
    
    var imageSelected = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        captionField.delegate = self
        
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        DataService.ds.REF_POSTS.observe(.value, with: { (snapshot) in
            self.posts = []
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshot {
                    print("SNAP:\(snap)")
                    if let postDict = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        let post = Post(postKey: key, postData: postDict)
                        self.posts.append(post)
                    }
                }
            }
            self.tableView.reloadData()
        })
    }
    
    
    // ************************Table view configuration************************
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as? PostCell {
            
            if let img = FeedVC.imageCache.object(forKey: post.imageUrl as NSString) {
                cell.configureCell(post: post, img: img)
                return cell
            } else {
                cell.configureCell(post: post)
                return cell
            }
        } else {
            return PostCell()
        }
    }
    
    
    // **********************************END************************************
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage{
            imageAdd.image = image
            imageSelected = true
        } else {
            print("***REZA*** A valid image wasn't selected")
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func addImageTapped(_ sender: Any) {
        
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    @IBAction func postBtnTapped(_ sender: Any) {
        
        guard let caption = captionField.text, caption != "" else {
            
            print("***REZA*** caption must be entered")
            return
        }
        
        guard let img = imageAdd.image, imageSelected == true else {
            print("***REZA*** Image must be selected")
            return
        }
        
        if let imageData = UIImageJPEGRepresentation(img, 0.2) {
            
            // pass to firebase storage
            
            let imgUid = NSUUID().uuidString
            
            let metaData = FIRStorageMetadata()
            metaData.contentType = "image/jpg"
            
            DataService.ds.REF_POST_IMAGES.child(imgUid).put(imageData, metadata: metaData) {
                (metaData, error) in
                if error != nil {
                    print("***REZA*** unable to upload image to firebase storage")
                } else {
                    print("***REZA*** successfuly uploaded image to firebase storage")
                    let downloadUrl = metaData?.downloadURL()?.absoluteString
                    
                    if let url = downloadUrl {
                        self.postToFirebase(imgUrl: url)
                    }
                }
            }
            
        }
    }
    
    func postToFirebase (imgUrl: String) {
        
        let post : Dictionary<String, Any> = [
            "caption": captionField.text!,
            "imageUrl": imgUrl,
            "likes": 0
        ]
        
        let firebasePost = DataService.ds.REF_POSTS.childByAutoId()
        firebasePost.setValue(post)
        
        imageSelected = false
        captionField.text = ""
        imageAdd.image = UIImage(named: "add-image")
        tableView.reloadData()
    }
    
    @IBAction func signOutTapped(_ sender: Any) {
        
        let keychainResult = KeychainWrapper.standard.removeObject(forKey: KEY_UID)
        print("***REZA*** UID Removed from keychain: \(keychainResult)")
        try! FIRAuth.auth()?.signOut()
        //            performSegue(withIdentifier: "goToSignIn", sender: nil)
        self.dismiss(animated: true, completion: nil)
        
        
    }
    
    // Disapear keyboard if user touches any area in the app
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    //Dismiss keyboard when you tuch or user push return in they keyboard
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        captionField.resignFirstResponder()
        return true
    }

    
}
