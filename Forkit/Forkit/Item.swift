//
//  Item.swift
//  Forkit
//
//  Created by VERDVANA on 2026/5/24.
//

import Foundation
import SwiftData

@Model
final class Dish {
    var id: UUID
    var name: String
    var category: String
    var note: String
    var imageURL: String?
    var createdAt: Date
    var isBuiltIn: Bool

    @Attribute(.externalStorage)
    var photoData: Data?

    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        note: String = "",
        imageURL: String? = nil,
        photoData: Data? = nil,
        createdAt: Date = .now,
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.note = note
        self.imageURL = imageURL
        self.photoData = photoData
        self.createdAt = createdAt
        self.isBuiltIn = isBuiltIn
    }
}

struct DefaultDish {
    let name: String
    let category: String
    let note: String
    let imageURL: String
}

enum DefaultMenu {
    static let categories = ["早饭", "凉菜", "牛肉", "鸡肉", "猪肉", "鱼虾", "素菜", "主食", "粥", "粗粮"]

    static let dishes: [DefaultDish] = [
        .init(name: "菜包子", category: "早饭", note: "热乎的早餐选择，适合配豆浆。", imageURL: foodImage("photo-1601050690597-df0568f70950")),
        .init(name: "鸡蛋", category: "早饭", note: "简单补蛋白，煎煮都可以。", imageURL: foodImage("photo-1582722872445-44dc5f7e3c8f")),
        .init(name: "酸奶", category: "早饭", note: "清爽轻食，适合搭配粗粮。", imageURL: foodImage("photo-1571212515416-fef01fc43637")),
        .init(name: "豆浆", category: "早饭", note: "温润早餐饮品。", imageURL: foodImage("photo-1558818498-28c1e002b655")),
        .init(name: "小米饭", category: "早饭", note: "清淡暖胃。", imageURL: foodImage("photo-1516684732162-798a0062be99")),

        .init(name: "菠菜粉丝", category: "凉菜", note: "清爽开胃。", imageURL: foodImage("photo-1512621776951-a57141f2eefd")),
        .init(name: "凉拌黄瓜", category: "凉菜", note: "脆爽解腻。", imageURL: foodImage("photo-1566842600175-97dca3c5ad8d")),
        .init(name: "凉拌莴笋丝", category: "凉菜", note: "清香爽口。", imageURL: foodImage("photo-1540420773420-3366772f4999")),
        .init(name: "凉拌藕片", category: "凉菜", note: "微辣更下饭。", imageURL: foodImage("photo-1540420773420-3366772f4999")),
        .init(name: "凉拌茄子", category: "凉菜", note: "蒜香软糯。", imageURL: foodImage("photo-1512621776951-a57141f2eefd")),
        .init(name: "凉拌黑木耳", category: "凉菜", note: "酸辣爽脆。", imageURL: foodImage("photo-1512621776951-a57141f2eefd")),

        .init(name: "芹菜牛肉", category: "牛肉", note: "快炒香气足。", imageURL: foodImage("photo-1600891964092-4316c288032e")),
        .init(name: "香菜牛肉", category: "牛肉", note: "香菜党优先。", imageURL: foodImage("photo-1600891964092-4316c288032e")),
        .init(name: "煎牛排", category: "牛肉", note: "适合想吃一顿扎实的。", imageURL: foodImage("photo-1558030006-450675393462")),

        .init(name: "咖喱鸡块", category: "鸡肉", note: "浓郁下饭。", imageURL: foodImage("photo-1565557623262-b51c2513a641")),
        .init(name: "宫保鸡丁", category: "鸡肉", note: "甜辣花生香。", imageURL: foodImage("photo-1525755662778-989d0524087e")),
        .init(name: "可乐鸡翅", category: "鸡肉", note: "咸甜家常菜。", imageURL: foodImage("photo-1527477396000-e27163b481c2")),
        .init(name: "炖鸡腿", category: "鸡肉", note: "软烂入味。", imageURL: foodImage("photo-1598515214211-89d3c73ae83b")),

        .init(name: "炖排骨", category: "猪肉", note: "适合慢炖。", imageURL: foodImage("photo-1544025162-d76694265947")),
        .init(name: "香菇炒肉", category: "猪肉", note: "家常快手。", imageURL: foodImage("photo-1525755662778-989d0524087e")),
        .init(name: "青椒炒肉", category: "猪肉", note: "经典下饭。", imageURL: foodImage("photo-1525755662778-989d0524087e")),
        .init(name: "菜花炒肉", category: "猪肉", note: "荤素均衡。", imageURL: foodImage("photo-1525755662778-989d0524087e")),

        .init(name: "虾仁西兰花", category: "鱼虾", note: "清淡高蛋白。", imageURL: foodImage("photo-1559847844-5315695dadae")),
        .init(name: "蒜蓉虾仁粉丝娃娃菜", category: "鱼虾", note: "蒜香浓，适合分享。", imageURL: foodImage("photo-1565680018434-b513d5e5fd47")),
        .init(name: "香煎三文鱼", category: "鱼虾", note: "外焦里嫩。", imageURL: foodImage("photo-1485921325833-c519f76c4927")),
        .init(name: "炸带鱼", category: "鱼虾", note: "酥香家常。", imageURL: foodImage("photo-1534766555764-ce878a5e3a2b")),
        .init(name: "红烧鲳鱼", category: "鱼虾", note: "酱香下饭。", imageURL: foodImage("photo-1534766555764-ce878a5e3a2b")),
        .init(name: "清蒸鲈鱼", category: "鱼虾", note: "鲜味清爽。", imageURL: foodImage("photo-1534766555764-ce878a5e3a2b")),

        .init(name: "酸辣土豆丝", category: "素菜", note: "爽脆酸辣。", imageURL: foodImage("photo-1512621776951-a57141f2eefd")),
        .init(name: "蚝油生菜", category: "素菜", note: "清甜快手。", imageURL: foodImage("photo-1512621776951-a57141f2eefd")),
        .init(name: "莴笋炒蛋", category: "素菜", note: "清香柔和。", imageURL: foodImage("photo-1512621776951-a57141f2eefd")),
        .init(name: "番茄炒蛋", category: "素菜", note: "酸甜家常。", imageURL: foodImage("photo-1565299507177-b0ac66763828")),
        .init(name: "葱炒豆腐", category: "素菜", note: "朴素耐吃。", imageURL: foodImage("photo-1512621776951-a57141f2eefd")),
        .init(name: "韭菜豆芽", category: "素菜", note: "清爽快炒。", imageURL: foodImage("photo-1512621776951-a57141f2eefd")),
        .init(name: "青椒豆干", category: "素菜", note: "香辣耐嚼。", imageURL: foodImage("photo-1512621776951-a57141f2eefd")),
        .init(name: "香菇油菜", category: "素菜", note: "鲜香清淡。", imageURL: foodImage("photo-1512621776951-a57141f2eefd")),
        .init(name: "手撕包菜", category: "素菜", note: "锅气足。", imageURL: foodImage("photo-1512621776951-a57141f2eefd")),
        .init(name: "丝瓜炒蛋", category: "素菜", note: "清甜软嫩。", imageURL: foodImage("photo-1512621776951-a57141f2eefd")),

        .init(name: "米饭", category: "主食", note: "百搭主食。", imageURL: foodImage("photo-1516684732162-798a0062be99")),
        .init(name: "炒大米", category: "主食", note: "剩饭变主角。", imageURL: foodImage("photo-1603133872878-684f208fb84b")),
        .init(name: "葱花饼", category: "主食", note: "外酥里软。", imageURL: foodImage("photo-1565299624946-b28f40a0ae38")),
        .init(name: "溜饼", category: "主食", note: "家常饼类。", imageURL: foodImage("photo-1565299624946-b28f40a0ae38")),
        .init(name: "蒸饺", category: "主食", note: "一口一个。", imageURL: foodImage("photo-1496116218417-1a781b1c416c")),
        .init(name: "水饺", category: "主食", note: "经典选择。", imageURL: foodImage("photo-1496116218417-1a781b1c416c")),
        .init(name: "番茄肉酱意面", category: "主食", note: "酸甜浓郁。", imageURL: foodImage("photo-1563379926898-05f4575a45d8")),
        .init(name: "卤面", category: "主食", note: "酱香面食。", imageURL: foodImage("photo-1569718212165-3a8278d5f624")),
        .init(name: "炒饼", category: "主食", note: "一盘管饱。", imageURL: foodImage("photo-1565299624946-b28f40a0ae38")),
        .init(name: "面条", category: "主食", note: "热乎顺口。", imageURL: foodImage("photo-1569718212165-3a8278d5f624")),
        .init(name: "疙瘩汤", category: "主食", note: "暖胃汤食。", imageURL: foodImage("photo-1547592166-23ac45744acd")),

        .init(name: "八宝粥", category: "粥", note: "软糯香甜。", imageURL: foodImage("photo-1547592166-23ac45744acd")),
        .init(name: "小米绿豆汤", category: "粥", note: "清淡暖身。", imageURL: foodImage("photo-1547592166-23ac45744acd")),

        .init(name: "玉米", category: "粗粮", note: "清甜粗粮。", imageURL: foodImage("photo-1551754655-cd27e38d2076")),
        .init(name: "紫薯", category: "粗粮", note: "香甜饱腹。", imageURL: foodImage("photo-1518977676601-b53f82aba655")),
        .init(name: "贝贝南瓜", category: "粗粮", note: "粉糯香甜。", imageURL: foodImage("photo-1506917728037-b6af01a7d403"))
    ]

    private static func foodImage(_ id: String) -> String {
        "https://images.unsplash.com/\(id)?auto=format&fit=crop&w=1200&q=80"
    }
}
