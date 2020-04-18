// TextView.swift

import SwiftUI

protocol TextViewProtocol {
    var text: String { get set }
    var desireHeight: CGFloat? { get set }
}

fileprivate struct TextViewHeightModifier: ViewModifier {
    let minHeight: CGFloat?
    let maxHeight: CGFloat?
    let desiredHeight: CGFloat?
    
    func body(content: Content) -> some View {
        content
            .frame(height: minHeight != nil && maxHeight != nil
                ? min(maxHeight ?? .infinity, max(minHeight!, desiredHeight!))
                : nil)
    }
}

struct TextView<Placeholder: View>: View {
    @Binding private var text: String
    @State private var desiredHeight: CGFloat?
    
    private var style: TextViewStyle = .init()
    private var options: TextViewOptions = .init()
    private let minHeight: CGFloat?
    private let maxHeight: CGFloat?
    private let placeholder: Placeholder
 
    private var backgroundView: some View {
        Group {
            if text.isEmpty {
                placeholder.padding(.top, 8.0).padding(.leading, 4.0)
            }
        }
    }
    
    var body: some View {
        _TextView(text: $text, desireHeight: $desiredHeight, style: style, options: options)
            .modifier(TextViewHeightModifier(minHeight: minHeight, maxHeight: maxHeight, desiredHeight: desiredHeight))
            .background(backgroundView, alignment: .topLeading)
    }
}

struct TextViewStyle {
    var color: UIColor = .darkText
    var font: UIFont = .systemFont(ofSize: 14.0)
}

struct TextViewOptions {
    var maximumCharacter: Int = .max
    var minimumFontScale: Float? = nil
}

extension TextView where Placeholder == EmptyView {
    init(text: Binding<String>, minHeight: CGFloat? = nil, maxHeight: CGFloat? = nil) {
        self._text = text
        self._desiredHeight = State(initialValue: minHeight)
        
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.placeholder = EmptyView()
    }
}

extension TextView where Placeholder == Text{
    init(_ placeholder: String, text: Binding<String>, minHeight: CGFloat? = nil, maxHeight: CGFloat? = nil) {
        self._text = text
        self._desiredHeight = State(initialValue: minHeight)
        
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.placeholder = Text(placeholder).font(.system(size: 14.0))
    }
}

extension TextView {
    init(_ placeholder: Placeholder, text: Binding<String>, minHeight: CGFloat? = nil, maxHeight: CGFloat? = nil) {
        self._text = text
        self._desiredHeight = State(initialValue: minHeight)
        
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.placeholder = placeholder
    }
}

extension TextView {
    func textColor(_ color: UIColor) -> TextView {
        var view = self
        view.style.color = color
        return view
    }
    
    func maximumCharacterLength(_ length: Int) -> TextView {
        var view = self
        view.options.maximumCharacter = length
        return view
    }
    
    func font(_ font: UIFont) -> TextView {
        var view = self
        view.style.font = font
        return view
    }
    
    func adjustFontSizeToFit(minimumScaleFactor: Float = .leastNonzeroMagnitude) -> TextView {
        var view = self
        view.options.minimumFontScale = minimumScaleFactor
        return view
    }
}

fileprivate struct _TextView: UIViewRepresentable, TextViewProtocol {
    @Binding var text: String
    @Binding var desireHeight: CGFloat?
    
    var style: TextViewStyle
    var options: TextViewOptions
}

extension _TextView {
    class Coordinator: NSObject, UITextViewDelegate {
        fileprivate var textView: TextViewProtocol
        
        init(_ uiTextView: TextViewProtocol) {
            self.textView = uiTextView
            super.init()
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            return true
        }
        
        func textViewDidChange(_ textView: UITextView) {
            self.textView.text = textView.text
        }
    }
        
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        autoreleasepool {
            let textView = UITextView()
            textView.delegate = context.coordinator
            textView.backgroundColor = .clear
            textView.isScrollEnabled = true
            textView.isEditable = true
            textView.isUserInteractionEnabled = true
            textView.text = text
            textView.textColor = style.color
            textView.font = style.font
            return textView
        }
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        autoreleasepool {
            if uiView.text.count > options.maximumCharacter {
                uiView.text = String(text.dropLast(uiView.text.count - options.maximumCharacter))
            }
            
            if let scale = options.minimumFontScale {
                uiView.adjustFontSizeToFit(fontSize: style.font.pointSize, minimumScale: scale)
            }
            
            DispatchQueue.main.async {
                autoreleasepool {
                    if uiView.text.count <= self.options.maximumCharacter {
                        self.text = uiView.text
                    }
                    self.desireHeight = uiView.contentSize.height
                }
            }
        }
    }
}

extension UITextView {
    func adjustFontSizeToFit(fontSize: CGFloat, minimumScale: Float) {
        var fontDecrement: CGFloat = 0.0
        let originFontSize: CGFloat = fontSize

        repeat {
            let fontSize = originFontSize - fontDecrement
            font = font?.withSize(fontSize)
            fontDecrement += 0.5
        } while contentSize.height > 120.0 && (1 - (fontDecrement) / originFontSize) > CGFloat(minimumScale)
    }
}
