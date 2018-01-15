//
//  GamesViewController.swift
//  queRule
//
//  Created by Roger Florat on 12/01/18.
//  Copyright © 2018 Roger Florat. All rights reserved.
//

import UIKit
import CoreData

class GamesViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // Outlet
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var filterControl: UISegmentedControl!
    
    // Var
    var managedObjectContext : NSManagedObjectContext? = nil
    var lstGames : [Game] = [Game]()
    
    // Action
    @IBAction func filterChanged(_ sender: UISegmentedControl) {
        performGamesQuery()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.alwaysBounceVertical = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        performGamesQuery()
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if lstGames.count == 0 {
            let imageView = UIImageView(image: UIImage(named: "img_empty_screen"))
            imageView.contentMode = .center
            collectionView.backgroundView = imageView
        } else {
            collectionView.backgroundView = UIView()
        }
        
        return lstGames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GameCell", for: indexPath) as! GameCell
        
        let game = lstGames[indexPath.row]
        
        cell.lblTitle.text = game.title
        
        let highlightColor =  !game.borrowed ? #colorLiteral(red: 0.2039215686, green: 0.5960784314, blue: 0.8588235294, alpha: 1) : #colorLiteral(red: 0.9114902616, green: 0.3033598661, blue: 0.2382881045, alpha: 1)
        
        cell.lblBorrowed.attributedText = self.formatColours(string: "PRESTADO: \(game.borrowed ? "SI" : "NO")", color: highlightColor)
        
        if let borrowedTo = game.borrowedTo {
            cell.lblBorrowedTo.attributedText = self.formatColours(string: "A: \(borrowedTo)", color: highlightColor)
        } else {
            cell.lblBorrowedTo.attributedText = self.formatColours(string: "A: --", color: highlightColor)
        }
        
        if let borrowedDate = game.borrowedDate {
            let dateFormater = DateFormatter()
            dateFormater.dateFormat = "dd/MM/yyyy"
            
            cell.lblBorrowedDate.attributedText = self.formatColours(string: "FECHA: \(dateFormater.string(from: borrowedDate))", color: highlightColor)
        } else {
            cell.lblBorrowedDate.attributedText = self.formatColours(string: "FECHA: --", color: highlightColor)
        }
        
        if let image = game.image {
            cell.imageView.image = UIImage(data: image)
        }
        
        cell.layer.masksToBounds = false
        cell.layer.shadowOffset = CGSize(width: 1, height: 1)
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 0.2
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: self.view.frame.size.width - 20, height: 120.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "editGameSegue", sender: self)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        
        if (offsetY < -120)  {
            performSegue(withIdentifier: "addGameSegue", sender: self)
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
        if segue.identifier == "addGameSegue" {
            let addNavVC = segue.destination as! UINavigationController
            let addVC = addNavVC.topViewController as! AddGameViewController
            
            addVC.managerObjectContext = self.managedObjectContext
            addVC.delegate = self
        }
        
        if segue.identifier == "editGameSegue" {
            let addGameVC = segue.destination as! AddGameViewController
            addGameVC.managerObjectContext = self.managedObjectContext
            
            let selectedIndex = collectionView.indexPathsForSelectedItems?.first?.row
            let game = lstGames[selectedIndex!]
            
            addGameVC.game = game
            addGameVC.delegate = self
        }
        
    }
    
    func formatColours(string: String, color: UIColor) -> NSMutableAttributedString {
        let length = string.count
        let colonPosition = string.indexOf(target: ":")!
        
        let myMutableString = NSMutableAttributedString(string: string, attributes: nil)
        
        myMutableString.addAttribute(NSAttributedStringKey.foregroundColor, value: color, range: NSRange(location: 0, length: length))
        
        myMutableString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.black, range: NSRange(location: 0, length: colonPosition + 1))
        
        return myMutableString
        
    }
    
    func performGamesQuery() {
        
        let request: NSFetchRequest<Game> = Game.fetchRequest()
        let sortByDate = NSSortDescriptor(key: "dateCreated", ascending: false)
        
        request.sortDescriptors = [sortByDate]
        
        if filterControl.selectedSegmentIndex == 0 {
            let predicate = NSPredicate(format: "borrowed = true")
            request.predicate = predicate
        }
        
        do {
            
            let fetchedGames = try managedObjectContext?.fetch(request)
            
            if let fetchedGames = fetchedGames {
                lstGames = fetchedGames
                collectionView.reloadData()
            }
            
        } catch {
            print("Error recuperando datos de Core Data")
        }
        
    }
    
    
}

extension GamesViewController : AddGameViewControllerDelegate {
    func didAddGame() {
        self.collectionView.reloadData()
    }
    
}

extension String {
    func indexOf(target: String)  -> Int? {
        if let range = self.range(of: target) {
            return distance(from: self.startIndex, to: range.lowerBound)
        }
        
        return nil
    }
}
