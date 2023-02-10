//
//  TagManager.swift
//  DreamCalendar
//
//  Created by 이지수 on 2023/02/05.
//

import Foundation
import CoreData

final class TagManager {
    static private(set) var global: TagManager = TagManager(viewContext: NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType))
    
    static let tagKeys = (1...TagType.allCases.count)
    
    private let viewContext: NSManagedObjectContext
    private var tags: [Int:Tag] = [:]
    
    var tagCollection: [Tag] {
        return Self.tagKeys.compactMap({ self.tags[$0] }).sorted()
    }
    
    private init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    static func initializeGlobalTagManager (with context: NSManagedObjectContext) throws {
        let manager = TagManager(viewContext: context)
        let tags = try? manager.fetchAllTag()
        tags?.forEach() { tag in
            manager.tags.updateValue(tag, forKey: Int(tag.id))
        }
        Self.tagKeys.forEach { key in
            guard manager.tags[key] == nil else { return }
            let tag = Tag.defaultTag(context: context, id: Int16(key))
            manager.tags.updateValue(tag, forKey: key)
        }
        try context.save()
        Self.global = manager
        return
    }
    
    private func fetchAllTag() throws -> [Tag] {
        let request = Tag.fetchRequest()
        return try self.viewContext.fetch(request)
    }
}