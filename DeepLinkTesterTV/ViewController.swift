//
//  ViewController.swift
//  DeepLinkTesterTV
//
//  Created by Deepanshu Bajaj on 14/10/25.
//

import UIKit

struct SavedItem: Codable {
    let name: String
    let url: String

    var formatted: String {
        return "\(name)://\(url)"
    }
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let nameTextField = UITextField()
    let urlTextField = UITextField()
    let saveButton = UIButton(type: .system)
    let deleteButton = UIButton(type: .system)
    let openButton = UIButton(type: .system)

    let tableView = UITableView()

    var savedItems: [SavedItem] = []
    let savedKey = "savedDeepLinkItems"

    var selectedIndex: IndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .darkGray

        loadSavedItems()
        setupUI()
    }

    func setupUI() {
        setupTextFields()
        setupButtons()
        setupTableView()

        let stack = UIStackView(arrangedSubviews: [
            nameTextField,
            urlTextField,
            saveButton,
            deleteButton,
            tableView,
            openButton
        ])

        stack.axis = .vertical
        stack.spacing = 40
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.widthAnchor.constraint(equalToConstant: 1100),
            tableView.heightAnchor.constraint(equalToConstant: 300)
        ])
    }

    // MARK: - Textfields
    func setupTextFields() {
        [nameTextField, urlTextField].forEach {
            $0.backgroundColor = .white
            $0.textColor = .black
            $0.font = UIFont.systemFont(ofSize: 28)
            $0.textAlignment = .center
            $0.layer.cornerRadius = 12
            $0.heightAnchor.constraint(equalToConstant: 60).isActive = true
        }

        nameTextField.placeholder = "Enter name (e.g., monumental)"
        urlTextField.placeholder = "Enter deep link URL (https://...)"
    }

    // MARK: - Buttons
    func setupButtons() {
        setupButton(btn: saveButton, title: "Save", color: .systemBlue, action: #selector(saveItem))
        setupButton(btn: deleteButton, title: "Delete Selected", color: .systemRed, action: #selector(deleteSelected))
        setupButton(btn: openButton, title: "Open URL", color: .systemGreen, action: #selector(openURLPressed))
    }

    func setupButton(btn: UIButton, title: String, color: UIColor, action: Selector) {
        btn.setTitle(title, for: .normal)
        btn.backgroundColor = color
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 16
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 32)
        btn.heightAnchor.constraint(equalToConstant: 80).isActive = true
        btn.addTarget(self, action: action, for: .primaryActionTriggered)
    }

    // MARK: - Table View
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .lightGray
        tableView.layer.cornerRadius = 12
        tableView.rowHeight = 70
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    // MARK: - Save
    @objc func saveItem() {
        guard let name = nameTextField.text, !name.isEmpty,
              let url = urlTextField.text, !url.isEmpty else {
            return
        }

        // Store normally, but show as name://url
        savedItems.append(SavedItem(name: name, url: url))
        saveToUserDefaults()

        nameTextField.text = ""
        urlTextField.text = ""

        tableView.reloadData()
    }

    func saveToUserDefaults() {
        let data = try? JSONEncoder().encode(savedItems)
        UserDefaults.standard.set(data, forKey: savedKey)
    }

    func loadSavedItems() {
        if let data = UserDefaults.standard.data(forKey: savedKey),
           let items = try? JSONDecoder().decode([SavedItem].self, from: data) {
            savedItems = items
        }
    }

    // MARK: - Delete
    @objc func deleteSelected() {
        guard let index = selectedIndex else { return }

        savedItems.remove(at: index.row)
        saveToUserDefaults()

        selectedIndex = nil
        tableView.reloadData()
    }

    // MARK: - Open
    @objc func openURLPressed() {
        var finalURLString: String?

        // 1️⃣ If user typed new values → build scheme://url
        if let name = nameTextField.text, !name.isEmpty,
           let typedURL = urlTextField.text, !typedURL.isEmpty {
            finalURLString = "\(name)://\(typedURL)"
        }
        // 2️⃣ Else if user selected from table → build using selected item
        else if let index = selectedIndex {
            let item = savedItems[index.row]
            finalURLString = "\(item.name)://\(item.url)"
        }

        guard let urlStr = finalURLString,
              let url = URL(string: urlStr) else {
            print("❌ Invalid URL")
            return
        }

        print("Attempting to open:", urlStr)

        // 3️⃣ Use the EXACT open-app style you provided
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    print("✅ Opened App!")
                } else {
                    print("❌ Failed to open App.")
                }
            }
        } else {
            print("🚫 App not installed or deep link not available.")
        }
    }


    // MARK: - Tableview Delegates
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        savedItems.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = savedItems[indexPath.row]

        // display in required format
        cell.textLabel?.text = item.formatted
        cell.textLabel?.font = UIFont.systemFont(ofSize: 26)

        // highlight selected cell
        if selectedIndex == indexPath {
            cell.backgroundColor = .systemYellow
            cell.textLabel?.textColor = .black
        } else {
            cell.backgroundColor = .clear
            cell.textLabel?.textColor = .black
        }

        return cell
    }
}
