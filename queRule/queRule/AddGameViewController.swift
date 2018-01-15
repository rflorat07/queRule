//
//  AddGameViewController.swift
//  queRule
//
//  Created by Roger Florat on 12/01/18.
//  Copyright © 2018 Roger Florat. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation

protocol AddGameViewControllerDelegate {
    func didAddGame()
}

class AddGameViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // Outlet
    
    @IBOutlet weak var gameImageView: UIImageView!
    @IBOutlet weak var borrowedSwitch: UISwitch!
    @IBOutlet weak var txtTitle: UITextField!
    @IBOutlet weak var txtBorrowedTo: UITextField!
    @IBOutlet weak var txtBorrowedDate: UITextField!
    @IBOutlet weak var btnDelete: UIButton!
    
    // Var
    var managerObjectContext : NSManagedObjectContext? = nil
    
    var imagePickerController = UIImagePickerController()
    
    var cameraPermissions: Bool = false
    
    var delegate : AddGameViewControllerDelegate?
    
    var game : Game? = nil
    
    var datePiker : UIDatePicker!
    
    let dateFormatter = DateFormatter()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        /* keyboard */
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow , object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide , object: nil)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        self.view.addGestureRecognizer(tapGesture)
        
        let takePictureGesture = UITapGestureRecognizer(target: self, action: #selector(takePictureTapped))
        
        self.gameImageView.addGestureRecognizer(takePictureGesture)
        
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        
        datePiker = UIDatePicker(frame: CGRect(x: 0, y: 210, width: 320, height: 216))
        datePiker.datePickerMode = .date
        datePiker.addTarget(self, action: #selector(datePickerChangedValue), for: .valueChanged)
        txtBorrowedDate.inputView = datePiker
        
        if game == nil {
            self.title = "Añadir juego"
            
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonPressed))
            
            self.btnDelete.isHidden = true
            borrowedSwitch.isOn = true
            
        } else {
            
            self.title = "Detalles"
            self.txtTitle.text = game?.title
            
            if let borrwed = game?.borrowed {
                self.borrowedSwitch.isOn = borrwed
            }
            
            self.txtBorrowedTo.text = game?.borrowedTo
            
            if let borrowedDate = game?.borrowedDate {
                self.txtBorrowedDate.text = dateFormatter.string(from: borrowedDate)
            }
            
            if let imageData = game?.image {
                self.gameImageView.image = UIImage(data: imageData)
            }
            
            self.btnDelete.isHidden = false
            
        }
        
        if !borrowedSwitch.isOn {
            txtBorrowedTo.isEnabled = false
            txtBorrowedDate.isEnabled = false
        }
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkPermissions()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if game != nil {
            saveGame()
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardTime = (info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        
        UIView.animate(withDuration: keyboardTime) {
            self.view.frame.origin.y = -(keyboardFrame.height)
        }
        
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardTime = (info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        
        UIView.animate(withDuration: keyboardTime) {
            self.view.frame.origin.y = 0
        }
    }
    
    @objc func viewTapped() {
        for view in self.view.subviews  {
            if let textField = view as? UITextField {
                textField.resignFirstResponder()
            }
        }
    }
    
    func checkPermissions() {
        let cameraMediaType = AVMediaType.video
        let cameraAuthorisationsStatus = AVCaptureDevice.authorizationStatus(for: cameraMediaType)
        
        switch cameraAuthorisationsStatus {
        case .authorized:
            cameraPermissions = true
        case .restricted:
            cameraPermissions = false
        case .denied:
            cameraPermissions = false
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: cameraMediaType, completionHandler: {
                (granted) in
                self.cameraPermissions = granted
            })
        }
    }
    
    @objc func takePictureTapped() {
        
        guard cameraPermissions else {
            let permissionsAlertController = UIAlertController(title: "Permisos", message: "No tiene permisos para acceder a la cámara del dispositivo. Puede cambiar esta información en la app de Ajustes de IOS", preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "Aceptar", style: .default, handler: nil)
            
            permissionsAlertController.addAction(okAction)
            
            present(permissionsAlertController, animated: true, completion: nil)
            
            return
        }
        
        let alertControler = UIAlertController(title: "Añadir fotos del videojuego", message: "", preferredStyle: .actionSheet)
        
        let cameraOption = UIAlertAction(title: "Cámara", style: .default) {
            (alertAction) in
            self.imagePickerController.sourceType = .camera
            self.present(self.imagePickerController, animated: true, completion: nil)
        }
        
        let cameraRollOption = UIAlertAction(title: "Carrete", style: .default) {
            (alertAction) in
            self.imagePickerController.sourceType = .photoLibrary
            self.present(self.imagePickerController, animated: true, completion: nil)
        }
        
        let cancelOption = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        
        if UIImagePickerController.isCameraDeviceAvailable(.rear) {
            alertControler.addAction(cameraOption)
        }
        
        alertControler.addAction(cameraRollOption)
        alertControler.addAction(cancelOption)
        
        present(alertControler, animated: true, completion: nil)
        
    }
    
    
    @objc func datePickerChangedValue(picker: UIDatePicker){
        txtBorrowedDate.text = dateFormatter.string(from: picker.date)
    }
    
    @objc func saveButtonPressed(){
        saveGame()
        dismiss(animated: true, completion: nil)
    }
    
    @objc func cancelButtonPressed(){
        dismiss(animated: true, completion: nil)
    }
    
    func saveGame(){
        
        if let context = self.managerObjectContext {
            var editedGame: Game? = nil
            
            if game == nil {
                editedGame = Game(context: context)
            } else {
                editedGame = game
            }
            
            if let editedGame = editedGame {
                
                editedGame.dateCreated = NSDate() as Date
                if let title = txtTitle.text {
                    editedGame.title =  title
                }
                
                editedGame.borrowed = borrowedSwitch.isOn
                
                if let image = gameImageView.image {
                    editedGame.image = UIImagePNGRepresentation(image) as Data?
                } else {
                    editedGame.image = Data()
                }
                
                if editedGame.borrowed {
                    
                    if let borrowedTo = txtBorrowedTo.text {
                        editedGame.borrowedTo = borrowedTo.uppercased()
                    }
                    
                    if let strDate = txtBorrowedDate.text {
                        editedGame.borrowedDate = dateFormatter.date(from: strDate) as Date?
                    }
                    
                } else {
                    editedGame.borrowedTo = nil
                    editedGame.borrowedDate = nil
                }
                
                do {
                    try context.save()
                    self.delegate?.didAddGame()
                    
                } catch {
                    print("Ha habido un arror al guardar los datos en Core Data")
                }
                
            }
            
        }
        
    }
    
    @IBAction func switchValueChanged (_ sender: UISwitch) {
        if sender.isOn {
            txtBorrowedTo.isEnabled = true
            txtBorrowedDate.isEnabled = true
            txtBorrowedDate.text = dateFormatter.string(from: Date())
        } else {
            txtBorrowedTo.isEnabled = false
            txtBorrowedDate.isEnabled = false
            txtBorrowedTo.text = ""
            txtBorrowedDate.text = ""
        }
    }
    
    @IBAction func deletePressed() {
        
        if let context = self.managerObjectContext {
            context.delete(game!)
            game = nil
            delegate?.didAddGame()
            navigationController?.popViewController(animated: true)
        }
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.gameImageView.image = pickedImage
        }
        
        picker.dismiss(animated: true , completion: nil  )
        
    }
    
    
}
