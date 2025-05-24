//
//  BaseMapListViewController.swift
//  TeploserviceMap
//
//  Created by Murad Tataev on 24.05.2025.
//

import UIKit
import MapKit
import CoreData

// MARK: - Базовый класс для любого экрана "Карта + список"
class BaseMapListViewController<Item: NSManagedObject>: UIViewController, UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate {

    // --- Публичные свойства для дочерних классов ---
    let mapView = MKMapView()
    let tableView = UITableView()
    let floatingButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemBlue
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 21
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 6
        button.alpha = 0.4
        return button
    }()
    let mapTypeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "map.fill"), for: .normal)
        button.tintColor = .label
        button.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.92)
        button.layer.cornerRadius = 22
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.08
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 6
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
// Кнопка скрытия и показа таблицы
//    let toggleListButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.translatesAutoresizingMaskIntoConstraints = false
//        button.backgroundColor = .white
//        button.layer.cornerRadius = 22
//        button.layer.shadowOpacity = 0.3
//        button.layer.shadowOffset = CGSize(width: 0, height: 2)
//        button.setImage(UIImage(systemName: "list.bullet"), for: .normal)
//        button.tintColor = .systemBlue
//        return button
//    }()
//    view.addSubview(toggleListButton)
//    NSLayoutConstraint.activate([
//        toggleListButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
//        toggleListButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -15),
//        toggleListButton.widthAnchor.constraint(equalToConstant: 56),
//        toggleListButton.heightAnchor.constraint(equalToConstant: 56)
//    ])
//    toggleListButton.addTarget(self, action: #selector(toggleListVisibility), for: .touchUpInside)

    // --- Приватные свойства ---
    var items: [Item] = []
    var isTableViewHidden = false
    var tableViewHeightConstraint: NSLayoutConstraint?
    var mapViewHeightConstraint: NSLayoutConstraint?
    var tableViewTopConstraint: NSLayoutConstraint?

    // --- MARK: - Жизненный цикл ---
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupFloatingMenu()
        mapView.delegate = self
        tableView.dataSource = self
        tableView.delegate = self

        // Добавляем tap для скрытия/отображения таблицы
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        tapRecognizer.cancelsTouchesInView = false
        mapView.addGestureRecognizer(tapRecognizer)

        // Долгое нажатие по таблице (можно расширять в дочерних)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleTableLongPress(_:)))
        tableView.addGestureRecognizer(longPress)

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleMapLongPress(_:)))
        longPressRecognizer.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressRecognizer)
    }

    // --- MARK: - UI Setup ---
    func setupUI() {
        view.addSubview(mapView)
        view.addSubview(tableView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        mapViewHeightConstraint = mapView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6)
        tableViewTopConstraint = tableView.topAnchor.constraint(equalTo: mapView.bottomAnchor)
        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4)

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapViewHeightConstraint!,
            tableViewTopConstraint!,
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableViewHeightConstraint!
        ])

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "BaseCell")
        tableView.tableFooterView = UIView()

        view.addSubview(floatingButton)
        NSLayoutConstraint.activate([
            floatingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            floatingButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -24),
            floatingButton.widthAnchor.constraint(equalToConstant: 44),
            floatingButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        view.addSubview(mapTypeButton)
        NSLayoutConstraint.activate([
            mapTypeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 18),
            mapTypeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            mapTypeButton.widthAnchor.constraint(equalToConstant: 44),
            mapTypeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        mapTypeButton.addTarget(self, action: #selector(showMapTypeMenu), for: .touchUpInside)
    }

    // --- MARK: - Floating Menu (переопределять в дочерних) ---
    func setupFloatingMenu() {
        floatingButton.showsMenuAsPrimaryAction = true
        floatingButton.menu = UIMenu(title: "", children: [
            UIAction(title: "Добавить", image: UIImage(systemName: "plus")) { [weak self] _ in
                self?.showAddItemAlert()
            }
            // Можно добавить импорт/экспорт в дочерних
        ])
    }

    // --- MARK: - Смена режима карты ---
    @objc func showMapTypeMenu() {
        let alert = UIAlertController(title: "Тип карты", message: nil, preferredStyle: .actionSheet)
        let types: [(String, MKMapType)] = [
            ("Стандарт", .standard),
            ("Спутник", .satellite),
            ("Гибрид", .hybrid)
        ]
        for (title, type) in types {
            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.mapView.mapType = type
            }
            if mapView.mapType == type {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = mapTypeButton.frame
        }
        present(alert, animated: true)
    }

    // --- MARK: - Скрыть/Показать таблицу ---
    @objc func toggleListVisibility() {
        isTableViewHidden.toggle()
        if isTableViewHidden {
            mapViewHeightConstraint?.isActive = false
            mapView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            tableView.isHidden = true
        } else {
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = false
            mapViewHeightConstraint?.isActive = true
            tableView.isHidden = false
        }
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    // --- MARK: - Тап на карту ---
    @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
        toggleListVisibility()
    }

    // --- В BaseMapListViewController ---
    @objc func handleMapLongPress(_ gesture: UILongPressGestureRecognizer) {
        // Пустая реализация — дочерние классы реализуют свою логику
    }

    // --- MARK: - UITableViewDataSource (переопределять в дочерних) ---
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Переопредели в дочернем классе!
        let cell = tableView.dequeueReusableCell(withIdentifier: "BaseCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "BaseCell")
        cell.textLabel?.text = "Title"
        cell.detailTextLabel?.text = "Subtitle"
        return cell
    }

    // --- MARK: - UITableViewDelegate (переопределять в дочерних) ---
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}

    // --- MARK: - Свайп редактирования/удаления (переопределять в дочерних) ---
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Дочерние классы реализуют нужные действия
        return nil
    }

    // --- MARK: - Долгое нажатие по таблице (можно переопределять) ---
    @objc func handleTableLongPress(_ gesture: UILongPressGestureRecognizer) {}

    // --- MARK: - MKMapViewDelegate (можно расширять в дочерних) ---
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return MKOverlayRenderer(overlay: overlay)
    }

    // --- MARK: - Методы для работы с данными (реализуются в дочерних) ---
    func loadItems() {
        // Переопредели для загрузки объектов (BoilerHouse или SavedLocation)
    }

    func showAddItemAlert() {
        // Переопредели для показа алерта добавления
    }
}
