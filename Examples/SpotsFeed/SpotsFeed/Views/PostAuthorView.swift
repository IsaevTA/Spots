import UIKit
import Imaginary

public protocol PostAuthorViewDelegate: class {

  func authorDidTap()
}

open class PostAuthorView: UIView {

  public struct Dimensions {
    public static let avatarOffset: CGFloat = 10
    public static let avatarSize: CGFloat = 40
    public static let nameOffset: CGFloat = Dimensions.avatarOffset * 2 + Dimensions.avatarSize
    public static let nameTopOffset: CGFloat = 12
    public static let dateTopOffset: CGFloat = 30
  }

  open lazy var avatarImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.layer.cornerRadius = Dimensions.avatarSize / 2
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.isOpaque = true
    imageView.backgroundColor = UIColor.white

    return imageView
    }()

  open lazy var authorLabel: UILabel = {
    let label = UILabel()
    label.font = FontList.Post.author

    return label
    }()

  open lazy var dateLabel: UILabel = {
    let label = UILabel()
    label.textColor = ColorList.Post.date
    label.font = FontList.Post.date

    return label
    }()

  open lazy var tapAuthorGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
    let gesture = UITapGestureRecognizer()
    gesture.addTarget(self, action: #selector(handleTapGestureRecognizer))

    return gesture
    }()

  open lazy var tapLabelGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
    let gesture = UITapGestureRecognizer()
    gesture.addTarget(self, action: #selector(handleTapGestureRecognizer))

    return gesture
    }()

  open weak var delegate: PostAuthorViewDelegate?

  // MARK: - Initialization

  public override init(frame: CGRect) {
    super.init(frame: frame)

    let views: [UIView] = [dateLabel, authorLabel, avatarImageView]
    views.forEach {
      addSubview($0)
      $0.isOpaque = true
      $0.backgroundColor = UIColor.white
      $0.isUserInteractionEnabled = true
      $0.layer.drawsAsynchronously = true
    }

    avatarImageView.addGestureRecognizer(tapAuthorGestureRecognizer)
    authorLabel.addGestureRecognizer(tapLabelGestureRecognizer)
    backgroundColor = UIColor.white
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Setup

  open override func draw(_ rect: CGRect) {
    super.draw(rect)

    avatarImageView.frame = CGRect(x: Dimensions.avatarOffset, y: Dimensions.avatarOffset,
      width: Dimensions.avatarSize, height: Dimensions.avatarSize)
    authorLabel.frame = CGRect(x: Dimensions.nameOffset, y: Dimensions.nameTopOffset,
      width: UIScreen.main.bounds.width - 70, height: 20)
    dateLabel.frame = CGRect(x: Dimensions.nameOffset, y: Dimensions.dateTopOffset,
      width: UIScreen.main.bounds.width - 70, height: 17)
  }

  open func configureView(_ author: Author, date: String) {
    if let avatarURL = author.avatar {
      avatarImageView.setImage(avatarURL)
    }

    authorLabel.text = author.name
    dateLabel.text = date
  }

  // MARK: - Actions

  open func handleTapGestureRecognizer() {
    delegate?.authorDidTap()
  }
}
