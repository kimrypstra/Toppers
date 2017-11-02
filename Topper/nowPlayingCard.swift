//
//  NowPlayingCard.swift
//  Topper
//
//  Created by Kim Rypstra on 15/10/17.
//  Copyright © 2017 Kim Rypstra. All rights reserved.
//

import UIKit

class NowPlayingCard: UIView, UIGestureRecognizerDelegate {

    @IBOutlet weak var previousImageConstraint: NSLayoutConstraint!
    @IBOutlet weak var nextImageConstraint: NSLayoutConstraint!
    @IBOutlet weak var previousImage: UIImageView!
    @IBOutlet weak var nextImage: UIImageView!
    @IBOutlet weak var backgroundViewCenterConstraint: NSLayoutConstraint!
    @IBOutlet var panGestureRecog: UIPanGestureRecognizer!
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var albumArtImageView: UIImageView!
    @IBOutlet weak var desaturatedAlbumArtImageView: UIImageView!
    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var albumNameLabel: UILabel!
    @IBOutlet var tapRecog: UITapGestureRecognizer!
    @IBOutlet weak var backgroundViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var shadowView: UIView!
    
    var paused = false
    var delegate: NowPlayingDelegate!
    var skipTrackTriggered = false
    var shrunkPercentage: CGFloat = 0.8
    let trackChangeTriggerDistance: CGFloat = 60
    var firstTouchLocation: CGPoint? = nil
    var draggedDistance: CGFloat? = nil {
        didSet {
            if draggedDistance != nil {
                //print(draggedDistance)
                backgroundViewCenterConstraint.constant = draggedDistance!
                if draggedDistance! > trackChangeTriggerDistance {
                    skipTrackTriggered = true
                    UIView.animate(withDuration: 0.5, animations: {
                        self.nextImage.alpha = 1
                    })
                } else if draggedDistance! < trackChangeTriggerDistance * -1 {
                    skipTrackTriggered = true
                    UIView.animate(withDuration: 0.5, animations: {
                        self.previousImage.alpha = 1
                    })
                } else {
                    skipTrackTriggered = false 
                    UIView.animate(withDuration: 0.5, animations: {
                        self.previousImage.alpha = 0
                        self.nextImage.alpha = 0
                    })
                }
            } else {
                backgroundViewCenterConstraint.constant = 0
                if skipTrackTriggered == false {
                    UIView.animate(withDuration: 0.25, animations: {
                        self.layoutIfNeeded()
                    })
                }

                
            }
        }
    }
    
    @IBAction func didTapImage(_ sender: UITapGestureRecognizer) {
        delegate.didTriggerPausePlay()
        print("tappa")
        
        
    }
    
    func setTextColour(color: UIColor) {
        self.trackNameLabel.textColor = color
        self.albumNameLabel.textColor = color
        self.artistNameLabel.textColor = color
        self.nextImage.tintColor = color
        self.previousImage.tintColor = color 
    }
    
    func setBackgroundColour(color: UIColor) {
        self.backgroundView.backgroundColor = color
        //self.shadowView.backgroundColor = color.withAlphaComponent(0.5)
    }
    
    func toggleShrink() {
        desaturatedAlbumArtImageView.image = desaturatedImage(_from: albumArtImageView.image!)
        if !paused {
            paused = true
            backgroundViewWidthConstraint.constant -= 20
            backgroundViewHeightConstraint.constant -= 20
            UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
                self.desaturatedAlbumArtImageView.alpha = 0.75
                self.layoutIfNeeded()
            }, completion: nil)
            
        } else {
            paused = false
            backgroundViewWidthConstraint.constant = 0
            backgroundViewHeightConstraint.constant = 0
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
                self.desaturatedAlbumArtImageView.alpha = 0
                self.roundCorners()
                self.layoutIfNeeded()
            }, completion: nil)
            
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //print("Touches began from \(touches.first?.gestureRecognizers)")
        guard let touch = touches.first else {
            return
        }
        firstTouchLocation = touch.location(in: backgroundView.superview)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        let offset = touch.location(in: backgroundView.superview).x - (firstTouchLocation?.x)!
        draggedDistance = offset
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard draggedDistance != nil else {return}
        
        if draggedDistance! > trackChangeTriggerDistance {
            prevTrack()
        } else if draggedDistance! < trackChangeTriggerDistance * -1 {
            nextTrack()
        } else {
            draggedDistance = nil
            firstTouchLocation = nil
        }
        self.previousImage.alpha = 0
        self.nextImage.alpha = 0

    }
    
    func nextTrack() {
        delegate.didTriggerNextTrack()
    }
    
    func prevTrack() {
        delegate.didTriggerPreviousTrack()
    }
    
    func resetCard(fast: Bool) {
        if fast {
            draggedDistance = nil
            firstTouchLocation = nil
        } else {
            skipTrackTriggered = false
            draggedDistance = nil
            firstTouchLocation = nil
        }

    }

    func roundCorners() {
        let maskPath = UIBezierPath.init(roundedRect: self.albumArtImageView.bounds, byRoundingCorners: [.topLeft, UIRectCorner.topRight], cornerRadii: CGSize(width: 8, height: 8))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.albumArtImageView.bounds
        maskLayer.path = maskPath.cgPath
        //self.albumArtImageView.layer.mask = maskLayer
    }
    
    func desaturatedImage(_from image: UIImage) -> UIImage? {
        let beginImage = CIImage(cgImage: image.cgImage!)
        guard let filter = CIFilter(name: "CIColorControls") else {
            print("E2")
            return nil
        }
        filter.setValue(beginImage, forKey: kCIInputImageKey)
        filter.setValue(0.0, forKey: kCIInputSaturationKey)
        guard let output = filter.outputImage else {
            print("E3")
            return nil
        }
        let context = CIContext(options: nil)
        let imageRef = context.createCGImage(output, from: beginImage.extent)
        return UIImage(cgImage: imageRef!)
    }

    
    private func commonInit() {
        Bundle.main.loadNibNamed("NowPlayingCard", owner: self, options: nil)
        self.backgroundColor = .clear
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        backgroundView.layer.cornerRadius = 8
        shadowView.layer.cornerRadius = 8
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 10)
        shadowView.layer.shadowRadius = 10
        shadowView.layer.shadowOpacity = 0.4
        shadowView.clipsToBounds = false
        backgroundView.clipsToBounds = true
        previousImage.image = previousImage.image?.withRenderingMode(.alwaysTemplate)
        nextImage.image = nextImage.image?.withRenderingMode(.alwaysTemplate)
        
    }
    
}
