//
//  MealTabs.swift
//  MealKit
//
//  Created by Developer on 5/14/20.
//  Copyright © 2020 Developer. All rights reserved.
//

import UIKit

/*
 Last thing should be setting this in storyboard
 */

class MealTabs: UITabBarController {
    override func viewDidLoad() {
        self.viewControllers = [MealNVC(type: .snack), MealNVC(type: .breakfast), MealNVC(type: .lunch), MealNVC(type: .dinner), MealNVC(type: .cart)]
        self.selectedIndex = 1
        self.view.tintColor = .systemGreen
        
    }
}


enum MealType: String {
    case snack = "snacks"
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case cart = "cart"
    
    var name: String {
        return self.rawValue
    }
    
    var imageName : String {
        switch self {
            case .snack: return "sparkles"
            case .cart: return "cart"
            case .breakfast: return "sunrise"
            case .lunch: return "sun.max"
            case .dinner: return "sunset"
        }
    }
    
    var selectedImageName : String {
        switch self {
            case .snack: return "sparkles"
            case .cart: return "cart.fill"
            case .breakfast: return "sunrise.fill"
            case .lunch: return "sun.max.fill"
            case .dinner: return "sunset.fill"
        }
    }
    
}

class MealNVC : UINavigationController {
    
    init(type: MealType) {
        super.init(rootViewController: MealVC(type: type))
        self.tabBarItem = UITabBarItem(title: type.name, image: UIImage(systemName: type.imageName), selectedImage: UIImage(systemName: type.selectedImageName))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}

protocol MealVCDelegate: class {
    func reloadData()
}

class MealVC: UIViewController, UITableViewDelegate, UITableViewDataSource, MealVCDelegate {
    
    weak var delegate: MealVCDelegate?
    let type: MealType
    var table: UITableView!
    var data : [MealData] = []
    var archive : Bool
    let refreshControl = UIRefreshControl()
    
    init(type: MealType, archive: Bool=false){
        self.type = type
        self.archive = archive
        super.init(nibName: nil, bundle: nil)
        self.title = archive ? "archive" : type.name
        self.data = CoreDataSingleton.shared.getMealsFor(type: type, archived: archive)
        self.view.backgroundColor = .systemBackground
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func setup(){
        addTable()
    }
    
    @objc func refreshData(){
        self.data = CoreDataSingleton.shared.getMealsFor(type: type, archived: archive)
        self.table.reloadData()
        refreshControl.endRefreshing()
    }
    
    func addTable(){
        table = UITableView(frame: .zero)
        table.register(SimpleCell.self, forCellReuseIdentifier: "SimpleCell")
        table.translatesAutoresizingMaskIntoConstraints = false
        table.dataSource = self
        table.delegate = self
        table.tableFooterView = UIView()
        self.view.addSubview(table)
        
        table.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        
        NSLayoutConstraint(item: table!, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: table!, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: table!, attribute: .top, relatedBy: .equal, toItem: self.view.safeAreaLayoutGuide, attribute: .top, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: table!, attribute: .bottom, relatedBy: .equal, toItem: self.view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        
    }
    
    @objc func reloadData() {
        self.data = CoreDataSingleton.shared.getMealsFor(type: type, archived: archive)
        self.table.reloadData()
    }
    
    override func viewDidLoad() {

        if archive {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(closeTapped))
        }
        else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(plusTapped))
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "clock"), style: .plain, target: self, action: #selector(historyTapped))
            if type == .cart {
                NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .refreshCart, object: nil)
            }
            else {
                NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .refreshMeals, object: nil)
            }
        }

    }
    
    @objc func closeTapped(){
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func historyTapped(){
        let historicalCart = MealVC(type: self.type, archive: true)
        historicalCart.delegate = self
        let vc = UINavigationController(rootViewController: historicalCart)
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc func plusTapped(){
        let ac = UIAlertController(title: "New Meal", message: nil, preferredStyle: .alert)
        ac.addTextField()

        let submitAction = UIAlertAction(title: "Save", style: .default) { [unowned ac] _ in
            let answer = ac.textFields![0]
            let meal = CoreDataSingleton.shared.saveMeal(name: answer.text!, note: "", type: self.type)
            self.data.insert(meal, at: 0)
            self.table.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
            // do something interesting with "answer" here
        }
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        ac.addAction(submitAction)
        present(ac, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.tintColor = .label
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SimpleCell", for: indexPath) as! SimpleCell
        cell.accessoryType = type == .cart ? .none : .disclosureIndicator
        cell.setTitle(data[indexPath.row].name)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if type != .cart && !archive {
            let ingredients = IngredientsVC()
            ingredients.title = self.data[indexPath.row].name
            ingredients.meal = self.data[indexPath.row]
            self.navigationController?.pushViewController(ingredients, animated: true)
        }
        
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let mealData = self.data[indexPath.row]
        let remove = UIContextualAction(style: .destructive, title: archive ? "Restore" : "Delete") { (action, sourceView, completionHandler) in
            CoreDataSingleton.shared.archive(!self.archive, identifier: mealData.identifier)
            self.data.remove(at: indexPath.row)
            self.table.deleteRows(at: [indexPath], with: .automatic)
            self.delegate?.reloadData()
            completionHandler(true)
        }
    

        let clearBackground = UIColor.init(displayP3Red: 0, green: 0, blue: 0, alpha: 0)

        var imageName = ""
        if archive {
            imageName = "arrowshape.turn.up.right"
        }
        else {
            if type == .cart {
                imageName = "checkmark"
            }
            else {
                imageName = "archivebox"
            }
        }
        
        remove.image = UIImage(systemName: imageName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))!.withTintColor(.label, renderingMode: .alwaysOriginal)
        remove.backgroundColor = clearBackground
        
        
        
        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
        impactGenerator.prepare()
        let addToCart = UIContextualAction(style: .normal, title: "Cart") { (action, sourceView, completionHandler) in
            
            if mealData.ingredients.count == 0 {
                _ = CoreDataSingleton.shared.saveMeal(name: mealData.name, note: mealData.name, type: .cart)
                impactGenerator.impactOccurred()
                NotificationCenter.default.post(name: .refreshCart, object: nil)
            }
            else {
                impactGenerator.impactOccurred()
                
                for ingredient in mealData.ingredients {
                    _ = CoreDataSingleton.shared.saveMeal(name: ingredient, note: mealData.name, type: .cart)
                }
                
                NotificationCenter.default.post(name: .refreshCart, object: nil)
            }
            completionHandler(true)
        }

        addToCart.image = UIImage(systemName: "cart", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))!.withTintColor(.label, renderingMode: .alwaysOriginal)
        addToCart.backgroundColor = clearBackground
        
        
        
        var actions = [remove]
        
        if type != .cart {
            actions.insert(addToCart, at: 0)
        }
        
        
        let delete = UIContextualAction(style: .destructive, title: "Delete") { (action, sourceView, completionHandler) in
            let mealData = self.data.remove(at: indexPath.row)
            CoreDataSingleton.shared.deleteMeal(identifier: mealData.identifier)
            self.table.deleteRows(at: [indexPath], with: .automatic)
            self.delegate?.reloadData()
            completionHandler(true)
        }
        
        delete.image = UIImage(systemName: "trash", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))!.withTintColor(.label, renderingMode: .alwaysOriginal)
        delete.backgroundColor = clearBackground
        
        if archive == true {
            actions.insert(delete, at: 0)
        }
        
        let swipeActionConfig = UISwipeActionsConfiguration(actions: actions)
        swipeActionConfig.performsFirstActionWithFullSwipe = true
        return swipeActionConfig
    }
    
}

class SimpleCell: UITableViewCell {
    var label : UILabel!
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func setup(){
        addLabel()
    }
    
    func setTitle(_ title: String) {
        label.text = title
    }
    
    func addLabel(){
        label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(label)
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textColor = .label
        
        NSLayoutConstraint(item: label!, attribute: .leading, relatedBy: .equal, toItem: self.contentView, attribute: .leading, multiplier: 1, constant: 20).isActive = true
        
        NSLayoutConstraint(item: label!, attribute: .trailing, relatedBy: .equal, toItem: self.contentView, attribute: .trailing, multiplier: 1, constant: -20).isActive = true
        
        NSLayoutConstraint(item: label!, attribute: .centerY, relatedBy: .equal, toItem: self.contentView, attribute: .centerY, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: label!, attribute: .top, relatedBy: .equal, toItem: self.contentView, attribute: .top, multiplier: 1, constant: 10).isActive = true
    }
}


class IngredientsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var meal: MealData?
    var table: UITableView!
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        addTable()
        addNavButton()
    }
    
    func addNavButton(){
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(plusTapped))
    }
    
    @objc func plusTapped(){
        let ac = UIAlertController(title: "Add Ingredient", message: nil, preferredStyle: .alert)
        ac.addTextField()

        let submitAction = UIAlertAction(title: "Add", style: .default) { [unowned ac] _ in
            let ingredient = ac.textFields![0].text
            self.meal!.ingredients.insert(ingredient!, at: 0)
            self.table.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
            CoreDataSingleton.shared.saveIngredients(self.meal!.ingredients, for: self.meal!.identifier)
            NotificationCenter.default.post(name: .refreshMeals, object: nil)
            // do something interesting with "answer" here
        }
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        ac.addAction(submitAction)
        present(ac, animated: true)
    }
    
    @objc func refreshData(){
        meal = CoreDataSingleton.shared.getMeal(identifier: meal!.identifier)
        table.reloadData()
        refreshControl.endRefreshing()
    }
    
    func addTable(){
        table = UITableView(frame: .zero)
        table.register(SimpleCell.self, forCellReuseIdentifier: "SimpleCell")
        table.translatesAutoresizingMaskIntoConstraints = false
        table.dataSource = self
        table.delegate = self
        table.tableFooterView = UIView()
        self.view.addSubview(table)
        

        table.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        
        NSLayoutConstraint(item: table!, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: table!, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: table!, attribute: .top, relatedBy: .equal, toItem: self.view.safeAreaLayoutGuide, attribute: .top, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: table!, attribute: .bottom, relatedBy: .equal, toItem: self.view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return meal?.ingredients.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SimpleCell", for: indexPath) as! SimpleCell
        cell.setTitle(meal!.ingredients[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let remove = UIContextualAction(style: .destructive, title: "Delete") { (action, sourceView, completionHandler) in
            self.meal?.ingredients.remove(at: indexPath.row)
            self.table.deleteRows(at: [indexPath], with: .automatic)
            CoreDataSingleton.shared.saveIngredients(self.meal!.ingredients, for: self.meal!.identifier)
            NotificationCenter.default.post(name: .refreshMeals, object: nil)
            completionHandler(true)
        }
    

        let clearBackground = UIColor.init(displayP3Red: 0, green: 0, blue: 0, alpha: 0)

        remove.image = UIImage(systemName:  "trash", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))!.withTintColor(.label, renderingMode: .alwaysOriginal)
        remove.backgroundColor = clearBackground
        
        
        
        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
        impactGenerator.prepare()
        let addToCart = UIContextualAction(style: .normal, title: "Cart") { (action, sourceView, completionHandler) in
            _ = CoreDataSingleton.shared.saveMeal(name: self.meal!.ingredients[indexPath.row], note: self.meal!.name, type: .cart)
            impactGenerator.impactOccurred()
            NotificationCenter.default.post(name: .refreshCart, object: nil)
            completionHandler(true)
        }

        addToCart.image = UIImage(systemName: "cart", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))!.withTintColor(.label, renderingMode: .alwaysOriginal)
        addToCart.backgroundColor = clearBackground
        
        
        
        let actions = [addToCart, remove]
        let swipeActionConfig = UISwipeActionsConfiguration(actions: actions)
        swipeActionConfig.performsFirstActionWithFullSwipe = true
        return swipeActionConfig
    }
}

extension Notification.Name {
    static var refreshCart = Notification.Name("refreshCart")
    static var refreshMeals = Notification.Name("refreshMeals")
}
