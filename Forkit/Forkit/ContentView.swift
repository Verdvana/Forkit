//
//  ContentView.swift
//  Forkit
//
//  Created by VERDVANA on 2026/5/24.
//

import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Dish.createdAt) private var dishes: [Dish]

    @State private var selectedCategory = "全部"
    @State private var searchText = ""
    @State private var pickedDish: Dish?
    @State private var showingAddDish = false
    @State private var selectedDishIDs: Set<UUID> = []
    @State private var shareItems: [Any] = []
    @State private var showingShareSheet = false
    @State private var editingDish: Dish?

    private var categories: [String] {
        let stored = Set(dishes.map(\.category))
        return ["全部"] + DefaultMenu.categories.filter { stored.contains($0) } + stored.subtracting(DefaultMenu.categories).sorted()
    }

    private var filteredDishes: [Dish] {
        dishes.filter { dish in
            let matchesCategory = selectedCategory == "全部" || dish.category == selectedCategory
            let matchesSearch = searchText.isEmpty ||
                dish.name.localizedStandardContains(searchText) ||
                dish.note.localizedStandardContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    PickPanel(
                        dish: pickedDish ?? filteredDishes.randomElement(),
                        dishCount: filteredDishes.count,
                        isSelected: { dish in selectedDishIDs.contains(dish.id) },
                        onToggleSelection: toggleSelection,
                        onPick: pickDish
                    )
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                Section {
                    categoryPicker
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                if filteredDishes.isEmpty {
                    ContentUnavailableView("没有找到这道菜", systemImage: "fork.knife", description: Text("换个分类或添加一道新菜。"))
                } else {
                    ForEach(filteredDishes) { dish in
                        HStack(spacing: 12) {
                            Button {
                                toggleSelection(for: dish)
                            } label: {
                                Image(systemName: selectedDishIDs.contains(dish.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(selectedDishIDs.contains(dish.id) ? Color.accentColor : Color.secondary)
                                    .frame(width: 28)
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                DishDetailView(dish: dish, categories: Array(Set(categories.filter { $0 != "全部" })).sorted())
                            } label: {
                                DishRow(dish: dish)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                editingDish = dish
                            } label: {
                                Label("编辑", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                    .onDelete(perform: deleteDishes)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("饭签")
            .searchable(text: $searchText, prompt: "搜索菜名或备注")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await prepareSelectedShare() }
                    } label: {
                        Label(selectedDishIDs.isEmpty ? "分享" : "分享 \(selectedDishIDs.count)", systemImage: "square.and.arrow.up")
                    }
                    .disabled(selectedDishIDs.isEmpty)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button {
                            selectedDishIDs.removeAll()
                        } label: {
                            Label("清空选择", systemImage: "xmark.circle")
                        }
                        .disabled(selectedDishIDs.isEmpty)

                        Button {
                            showingAddDish = true
                        } label: {
                            Label("添加菜", systemImage: "plus")
                        }
                    }
                }

            }
            .sheet(isPresented: $showingAddDish) {
                AddDishView(categories: Array(Set(categories.filter { $0 != "全部" })).sorted())
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: shareItems)
            }
            .sheet(item: $editingDish) { dish in
                EditDishView(dish: dish, categories: Array(Set(categories.filter { $0 != "全部" })).sorted())
            }
            .task {
                seedDefaultMenuIfNeeded()
            }
        }
    }

    private var categoryPicker: some View {
        HStack(spacing: 6) {
            Image(systemName: "chevron.left")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)

            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { category in
                        Button {
                            selectedCategory = category
                            pickedDish = nil
                        } label: {
                            Text(category)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .foregroundStyle(selectedCategory == category ? .white : .primary)
                                .background(selectedCategory == category ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.visible)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.06),
                        .init(color: .black, location: 0.94),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .accessibilityLabel("分类")
    }

    private func pickDish() {
        withAnimation(.snappy) {
            pickedDish = filteredDishes.randomElement()
        }
    }

    private func deleteDishes(offsets: IndexSet) {
        for index in offsets {
            let dish = filteredDishes[index]
            selectedDishIDs.remove(dish.id)
            modelContext.delete(dish)
        }
    }

    private func toggleSelection(for dish: Dish) {
        if selectedDishIDs.contains(dish.id) {
            selectedDishIDs.remove(dish.id)
        } else {
            selectedDishIDs.insert(dish.id)
        }
    }

    private func prepareSelectedShare() async {
        let selectedDishes = dishes.filter { selectedDishIDs.contains($0.id) }
        guard !selectedDishes.isEmpty else { return }

        shareItems = await DishShareBuilder.items(for: selectedDishes)
        showingShareSheet = true
    }

    private func seedDefaultMenuIfNeeded() {
        guard dishes.isEmpty else { return }

        for dish in DefaultMenu.dishes {
            modelContext.insert(
                Dish(
                    name: dish.name,
                    category: dish.category,
                    note: dish.note,
                    imageURL: dish.imageURL,
                    createdAt: .now,
                    isBuiltIn: true
                )
            )
        }
    }
}

private struct PickPanel: View {
    let dish: Dish?
    let dishCount: Int
    let isSelected: (Dish) -> Bool
    let onToggleSelection: (Dish) -> Void
    let onPick: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("这顿吃什么")
                        .font(.title2.bold())
                    Text(dishCount == 0 ? "先添加一道菜吧" : "\(dishCount) 道候选")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: onPick) {
                    Label("抽签", systemImage: "shuffle")
                }
                .buttonStyle(.borderedProminent)
                .foregroundStyle(.white)
                .disabled(dishCount == 0)
            }

            if let dish {
                Button {
                    onToggleSelection(dish)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: isSelected(dish) ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(isSelected(dish) ? Color.accentColor : Color.secondary)
                            .frame(width: 28)

                        DishThumbnail(dish: dish, size: 92)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(dish.name)
                                .font(.title3.bold())
                                .foregroundStyle(.primary)
                            Label(dish.category, systemImage: "tag")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if !dish.note.isEmpty {
                                Text(dish.note)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct DishRow: View {
    let dish: Dish

    var body: some View {
        HStack(spacing: 12) {
            DishThumbnail(dish: dish, size: 58)

            VStack(alignment: .leading, spacing: 4) {
                Text(dish.name)
                    .font(.headline)
                Text(dish.category)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !dish.note.isEmpty {
                    Text(dish.note)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct SelectableDishRow: View {
    let dish: Dish
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                .frame(width: 28)

            DishRow(dish: dish)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }
}

private struct DishDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let dish: Dish
    let categories: [String]

    @State private var shareItems: [Any] = []
    @State private var showingShareSheet = false
    @State private var showingEditDish = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                DishHeroImage(dish: dish)
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    Text(dish.name)
                        .font(.title.bold())
                        .fixedSize(horizontal: false, vertical: true)
                    Label(dish.category, systemImage: "tag")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    if !dish.note.isEmpty {
                        Text(dish.note)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    Task { await prepareShare() }
                } label: {
                    Label("分享这道菜", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(dish.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showingEditDish = true
                } label: {
                    Label("编辑", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    modelContext.delete(dish)
                    dismiss()
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: shareItems)
        }
        .sheet(isPresented: $showingEditDish) {
            EditDishView(dish: dish, categories: categories)
        }
    }

    private func prepareShare() async {
        shareItems = await DishShareBuilder.items(for: [dish])
        showingShareSheet = true
    }
}

private struct AddDishView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let categories: [String]

    @State private var name = ""
    @State private var category = "早饭"
    @State private var customCategory = ""
    @State private var note = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?

    private var categoryChoices: [String] {
        let merged = Array(Set(categories + DefaultMenu.categories)).sorted()
        return merged + ["新分类"]
    }

    private var resolvedCategory: String {
        category == "新分类" ? customCategory.trimmingCharacters(in: .whitespacesAndNewlines) : category
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !resolvedCategory.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("菜品") {
                    TextField("菜名", text: $name)

                    Picker("分类", selection: $category) {
                        ForEach(categoryChoices, id: \.self) { choice in
                            Text(choice).tag(choice)
                        }
                    }

                    if category == "新分类" {
                        TextField("分类名称", text: $customCategory)
                    }

                    TextField("备注", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("照片") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(photoData == nil ? "选择照片" : "更换照片", systemImage: "photo")
                    }

                    if let photoData, let image = UIImage(data: photoData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
            .navigationTitle("添加菜")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: saveDish)
                        .disabled(!canSave)
                }
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    photoData = try? await newItem?.loadTransferable(type: Data.self)
                }
            }
        }
    }

    private func saveDish() {
        let dish = Dish(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: resolvedCategory,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            photoData: photoData,
            createdAt: .now
        )
        modelContext.insert(dish)
        dismiss()
    }
}

private struct EditDishView: View {
    @Environment(\.dismiss) private var dismiss

    let dish: Dish
    let categories: [String]

    @State private var name: String
    @State private var category: String
    @State private var customCategory = ""
    @State private var note: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?

    init(dish: Dish, categories: [String]) {
        self.dish = dish
        self.categories = categories
        _name = State(initialValue: dish.name)
        _category = State(initialValue: dish.category)
        _note = State(initialValue: dish.note)
        _photoData = State(initialValue: dish.photoData)
    }

    private var categoryChoices: [String] {
        let merged = Array(Set(categories + DefaultMenu.categories + [dish.category])).sorted()
        return merged + ["新分类"]
    }

    private var resolvedCategory: String {
        category == "新分类" ? customCategory.trimmingCharacters(in: .whitespacesAndNewlines) : category
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !resolvedCategory.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("菜品") {
                    TextField("菜名", text: $name)

                    Picker("分类", selection: $category) {
                        ForEach(categoryChoices, id: \.self) { choice in
                            Text(choice).tag(choice)
                        }
                    }

                    if category == "新分类" {
                        TextField("分类名称", text: $customCategory)
                    }

                    TextField("备注", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("照片") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("更换照片", systemImage: "photo")
                    }

                    if photoData != nil {
                        Button(role: .destructive) {
                            photoData = nil
                            selectedPhoto = nil
                        } label: {
                            Label("移除自选照片", systemImage: "xmark.circle")
                        }
                    }

                    if let photoData, let image = UIImage(data: photoData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else {
                        DishHeroImage(dish: dish)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
            .navigationTitle("编辑菜品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: saveDish)
                        .disabled(!canSave)
                }
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    photoData = try? await newItem?.loadTransferable(type: Data.self)
                }
            }
        }
    }

    private func saveDish() {
        dish.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        dish.category = resolvedCategory
        dish.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        dish.photoData = photoData
        dismiss()
    }
}

private struct DishThumbnail: View {
    let dish: Dish
    let size: CGFloat

    var body: some View {
        DishHeroImage(dish: dish)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityHidden(true)
    }
}

private struct DishHeroImage: View {
    let dish: Dish

    var body: some View {
        Group {
            if let data = dish.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let imageURL = dish.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    case .empty:
                        placeholder
                            .overlay {
                                ProgressView()
                            }
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .clipped()
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemOrange), Color(.systemGreen), Color(.systemTeal)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 46, weight: .semibold))
                .foregroundStyle(.white.opacity(0.88))
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private enum DishShareBuilder {
    static func items(for dishes: [Dish]) async -> [Any] {
        let selected = dishes.filter { !$0.name.isEmpty }
        guard !selected.isEmpty else { return [] }

        let images = await loadImages(for: selected)
        let card = selected.count == 1
            ? makeSingleCard(for: selected[0], image: images[selected[0].id])
            : makeMultiCard(for: selected, images: images)

        return [card, shareText(for: selected)]
    }

    private static func loadImages(for dishes: [Dish]) async -> [UUID: UIImage] {
        var images: [UUID: UIImage] = [:]

        for dish in dishes {
            if let image = await image(for: dish) {
                images[dish.id] = image
            }
        }

        return images
    }

    private static func image(for dish: Dish) async -> UIImage? {
        if let data = dish.photoData {
            return UIImage(data: data)
        }

        guard
            let imageURL = dish.imageURL,
            let url = URL(string: imageURL),
            let (data, _) = try? await URLSession.shared.data(from: url)
        else {
            return nil
        }

        return UIImage(data: data)
    }

    private static func shareText(for dishes: [Dish]) -> String {
        if dishes.count == 1, let dish = dishes.first {
            return text(for: dish)
        }

        return dishes.enumerated().map { index, dish in
            "\(index + 1). \(text(for: dish))"
        }
        .joined(separator: "\n\n")
    }

    private static func text(for dish: Dish) -> String {
        var text = "今天吃：\(dish.name)\n分类：\(dish.category)"
        if !dish.note.isEmpty {
            text += "\n备注：\(dish.note)"
        }
        return text
    }

    private static func makeSingleCard(for dish: Dish, image: UIImage?) -> UIImage {
        let size = CGSize(width: 1080, height: dish.note.isEmpty ? 1320 : 1500)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { rendererContext in
            let rect = CGRect(origin: .zero, size: size)
            UIColor.systemBackground.setFill()
            rendererContext.fill(rect)

            let imageRect = CGRect(x: 0, y: 0, width: size.width, height: 880)
            if let image {
                drawImage(image, in: imageRect)
            } else {
                drawPlaceholder(in: imageRect)
            }

            UIColor.systemBackground.setFill()
            UIBezierPath(
                roundedRect: CGRect(x: 0, y: 820, width: size.width, height: size.height - 820),
                byRoundingCorners: [.topLeft, .topRight],
                cornerRadii: CGSize(width: 48, height: 48)
            ).fill()

            let sidePadding: CGFloat = 72
            let contentWidth = size.width - sidePadding * 2
            var y: CGFloat = 900

            drawText(
                dish.name,
                in: CGRect(x: sidePadding, y: y, width: contentWidth, height: 160),
                font: .systemFont(ofSize: 72, weight: .bold),
                color: .label
            )
            y += 150

            drawText(
                "分类：\(dish.category)",
                in: CGRect(x: sidePadding, y: y, width: contentWidth, height: 70),
                font: .systemFont(ofSize: 38, weight: .semibold),
                color: .secondaryLabel
            )
            y += 92

            if !dish.note.isEmpty {
                drawText(
                    "备注：\(dish.note)",
                    in: CGRect(x: sidePadding, y: y, width: contentWidth, height: 210),
                    font: .systemFont(ofSize: 42, weight: .regular),
                    color: .label
                )
                y += 230
            }

            drawText(
                "饭签 Forkit",
                in: CGRect(x: sidePadding, y: y, width: contentWidth, height: 60),
                font: .systemFont(ofSize: 30, weight: .medium),
                color: .tertiaryLabel
            )
        }
    }

    private static func makeMultiCard(for dishes: [Dish], images: [UUID: UIImage]) -> UIImage {
        let rowHeight: CGFloat = 260
        let size = CGSize(width: 1080, height: 300 + CGFloat(dishes.count) * rowHeight + 90)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { rendererContext in
            let rect = CGRect(origin: .zero, size: size)
            UIColor.systemBackground.setFill()
            rendererContext.fill(rect)

            let sidePadding: CGFloat = 64
            let contentWidth = size.width - sidePadding * 2

            drawText(
                "这顿吃这些",
                in: CGRect(x: sidePadding, y: 70, width: contentWidth, height: 90),
                font: .systemFont(ofSize: 64, weight: .bold),
                color: .label
            )
            drawText(
                "\(dishes.count) 道菜 · 饭签 Forkit",
                in: CGRect(x: sidePadding, y: 160, width: contentWidth, height: 56),
                font: .systemFont(ofSize: 34, weight: .medium),
                color: .secondaryLabel
            )

            var y: CGFloat = 250
            for (index, dish) in dishes.enumerated() {
                let imageRect = CGRect(x: sidePadding, y: y, width: 190, height: 190)
                if let image = images[dish.id] {
                    drawImage(image, in: imageRect)
                } else {
                    drawPlaceholder(in: imageRect)
                }

                let textX = sidePadding + 224
                drawText(
                    "\(index + 1). \(dish.name)",
                    in: CGRect(x: textX, y: y + 2, width: size.width - textX - sidePadding, height: 64),
                    font: .systemFont(ofSize: 44, weight: .bold),
                    color: .label
                )
                drawText(
                    "分类：\(dish.category)",
                    in: CGRect(x: textX, y: y + 72, width: size.width - textX - sidePadding, height: 44),
                    font: .systemFont(ofSize: 28, weight: .semibold),
                    color: .secondaryLabel
                )
                if !dish.note.isEmpty {
                    drawText(
                        "备注：\(dish.note)",
                        in: CGRect(x: textX, y: y + 122, width: size.width - textX - sidePadding, height: 86),
                        font: .systemFont(ofSize: 30, weight: .regular),
                        color: .label
                    )
                }

                y += rowHeight
            }
        }
    }

    private static func drawImage(_ image: UIImage, in rect: CGRect) {
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return }
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let scale = max(rect.width / imageSize.width, rect.height / imageSize.height)
        let scaledSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let drawRect = CGRect(
            x: rect.midX - scaledSize.width / 2,
            y: rect.midY - scaledSize.height / 2,
            width: scaledSize.width,
            height: scaledSize.height
        )

        context.saveGState()
        UIBezierPath(roundedRect: rect, cornerRadius: 24).addClip()
        image.draw(in: drawRect)
        context.restoreGState()
    }

    private static func drawPlaceholder(in rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.saveGState()
        UIBezierPath(roundedRect: rect, cornerRadius: 24).addClip()
        UIColor.systemOrange.setFill()
        context.fill(rect)

        let symbolRect = CGRect(x: rect.midX - 46, y: rect.midY - 46, width: 92, height: 92)
        UIImage(systemName: "fork.knife.circle.fill")?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
            .draw(in: symbolRect)
        context.restoreGState()
    }

    private static func drawText(_ text: String, in rect: CGRect, font: UIFont, color: UIColor) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.lineSpacing = 8

        text.draw(
            with: rect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraph
            ],
            context: nil
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Dish.self, inMemory: true)
}
