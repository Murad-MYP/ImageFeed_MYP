import UIKit

enum Colors {
    static let background = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) // #FFFFFF
    static let textPrimary = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0) // #000000
    static let textSecondary = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0) // #999999
    static let accent = UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0) // #007AFF
    static let cellBackground = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0) // #F5F5F5
    static let separator = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0) // #E5E5E5
    static let error = UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0) // #FF3B30
    static let success = UIColor(red: 0.2, green: 0.78, blue: 0.35, alpha: 1.0) // #34C759
    
    // Цвета для состояний кнопок
    static let buttonNormal = accent
    static let buttonHighlighted = UIColor(red: 0.0, green: 0.4, blue: 0.8, alpha: 1.0) // #0066CC
    static let buttonDisabled = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0) // #CCCCCC
    
    // Цвета для теней
    static let shadow = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.1) // rgba(0, 0, 0, 0.1)
    
    // Цвета для индикаторов загрузки
    static let loadingBackground = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5) // rgba(0, 0, 0, 0.5)
    static let loadingIndicator = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) // #FFFFFF
} 