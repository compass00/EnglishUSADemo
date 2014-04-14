//
//  ViewController.m
//  USALan
//
//  Created by JiaLi on 14-2-3.
//  Copyright (c) 2014年 JiaLi. All rights reserved.
//

#import "ViewController.h"
#import "LessonView.h"
#import "AudioPlayer.h"
#define SIZEOFBUTTON (IS_IPAD ? 128 : 48)
#define BUTTONOFFSET (IS_IPAD ? 20 : 0)
@interface ViewController ()
@property CycleScrollView* csView;
@property NSMutableArray* dataArray;
@property NSInteger buttonStatus;
@property (nonatomic, strong) AudioPlayer* player;
@property (nonatomic, strong) UIButton* backButton;
@property (nonatomic, strong) UILabel* pageNumberLabel;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.buttonStatus = 0;
    _player = [[AudioPlayer alloc] init];
        // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated {
    if (self.csView == nil) {
        UIInterfaceOrientation or = [self interfaceOrientation];// [[UIDevice currentDevice] orientation];
        CGRect f = [[UIScreen mainScreen] bounds];
        CGRect rc =  UIInterfaceOrientationIsPortrait(or)? CGRectMake(0, 0, f.size.width, f.size.height) :  CGRectMake(0, 0, f.size.height, f.size.width);
        _csView = [[CycleScrollView alloc] initWithFrame:CGRectMake(0, 0, rc.size.width, rc.size.height)];
        _csView.delegate = self;
        _csView.datasource = self;
        [self.view addSubview:_csView];
        self.csView = _csView;
        self.csView.currentPage = self.currentNumber;
        [self.csView reloadData];
        _backButton = [[UIButton alloc] initWithFrame:CGRectMake(2, 20, SIZEOFBUTTON, SIZEOFBUTTON)];
        UIImage* im = [UIImage imageNamed:@"back.png"];
        [_backButton setImage:im forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(backToThumb) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.backButton];
        
        
        _playButton = [[UIButton alloc] initWithFrame:CGRectMake((rc.size.width - (SIZEOFBUTTON + BUTTONOFFSET))/2, rc.size.height - (SIZEOFBUTTON + BUTTONOFFSET), SIZEOFBUTTON, SIZEOFBUTTON)];
        [_playButton setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
        [_playButton addTarget:self action:@selector(clickButton) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.playButton];
  
        _previousButton = [[UIButton alloc] initWithFrame:CGRectMake(_playButton.frame.origin.x - 2*SIZEOFBUTTON, rc.size.height - (SIZEOFBUTTON + BUTTONOFFSET), SIZEOFBUTTON, SIZEOFBUTTON)];
        [_previousButton setImage:[UIImage imageNamed:@"previous.png"] forState:UIControlStateNormal];
        [_previousButton addTarget:self action:@selector(clickPreviousButon) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.previousButton];
  
        _nextButton = [[UIButton alloc] initWithFrame:CGRectMake(_playButton.frame.origin.x + 2*SIZEOFBUTTON, rc.size.height - (SIZEOFBUTTON + BUTTONOFFSET), SIZEOFBUTTON, SIZEOFBUTTON)];
        [_nextButton setImage:[UIImage imageNamed:@"next.png"] forState:UIControlStateNormal];
        [_nextButton addTarget:self action:@selector(clickNextButton) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.nextButton];
        
        _pageNumberLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, rc.size.height - 44, rc.size.width, 44)];
        _pageNumberLabel.backgroundColor = [UIColor clearColor];
        _pageNumberLabel.text = [NSString stringWithFormat:@"%d / %d", self.currentNumber, self.totalCount];
        _pageNumberLabel.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:self.pageNumberLabel];
        
        self.view.backgroundColor = [UIColor colorWithRed:152.0/255.0 green:209.0/255.0 blue:240.0/255.0 alpha:1.0];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPlayNotification:) name:@"didPlayNotification" object:nil];
    }
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (NSInteger)numberOfPages
{
    return self.totalCount;
}

- (UIView *)pageAtIndex:(NSInteger)index
{
    if (index == 0) {
        if (self.currentNumber - 1 <= 0) {
            return nil;
        }
    }
    
    if (index == 2) {
        if (self.currentNumber + 1 > self.totalCount) {
            return nil;
        }

    }
    LessonView* lessonView = [[LessonView alloc] initWithFrame:CGRectMake(0, 0, self.csView.frame.size.width, self.csView.frame.size.height)];
    NSString* imagePath = nil;
    switch (index) {
        case 0:
        {
            NSInteger i = self.currentNumber - 1;
            imagePath = [self.delegate getDataPathWithOutSuffix:i];
        }
            break;
        case 1:
            imagePath = [self.delegate getDataPathWithOutSuffix:self.currentNumber];
            break;
        case 2:
        {
            NSInteger i = self.currentNumber +1;
            imagePath = [self.delegate getDataPathWithOutSuffix:i];
        }
            break;
            
        default:
            break;
    }
    UIImage* lessonImage = [UIImage imageWithContentsOfFile:[imagePath stringByAppendingString:@".jpg"]];
    [lessonView setLessonImage:lessonImage];
    if (IS_SAME) {
        NSString* lessonContent =  [NSString stringWithContentsOfFile:[imagePath stringByAppendingString:@".txt"] encoding: NSASCIIStringEncoding error:nil];
        [lessonView setLessonText:lessonContent];
        
    } else {
        NSRange range = [imagePath rangeOfString:@"/" options:NSBackwardsSearch];
        if (range.location != NSNotFound) {
            NSString* filename = [imagePath substringFromIndex:range.location+1];
            NSRange headerrange = [filename rangeOfString:HEADERSTRING];
            if (headerrange.location != NSNotFound) {
                NSString* textName = [filename substringFromIndex:headerrange.location+headerrange.length];
                NSRange chRange = [textName rangeOfString:@"-"];
                if (chRange.location != NSNotFound) {
                    NSInteger first = [[textName substringToIndex:chRange.location] integerValue];
                    NSInteger second = [[textName substringFromIndex:(chRange.location+1)] integerValue];
                    NSString* textfilename = [NSString stringWithFormat:@"%d-%d", first - RLATIONOFFSET, second + RLATIONOFFSET];
                    NSString* textPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingFormat:@"%@", @"/Data/Text/"];
                    
                    NSString* lessonContent =  [NSString stringWithContentsOfFile:[textPath stringByAppendingFormat:@"%@.txt", textfilename] encoding: NSASCIIStringEncoding error:nil];
                    [lessonView setLessonText:lessonContent];
                    
                }
            }
        }
        
    }
   return lessonView;
}

- (void)didTurnPage:(NSInteger)page {
    if (page == 0 && self.currentNumber != 1) {
        self.currentNumber--;
       _pageNumberLabel.text = [NSString stringWithFormat:@"%d / %d", self.currentNumber, self.totalCount];    }
    
    if (page == 2 && self.currentNumber != self.totalCount) {
        self.currentNumber++;
        _pageNumberLabel.text = [NSString stringWithFormat:@"%d / %d", self.currentNumber, self.totalCount];   }
}

- (BOOL)firstPage {
    return self.currentNumber == 1;
}

- (BOOL)lastPage {
    return self.currentNumber == self.totalCount;
}

- (void)backToThumb {
    [self dismissViewControllerAnimated:YES completion:^(void ) {}];
}

- (void)clickPreviousButon {
    [self.csView scrollToPrevious];
}

- (void)clickNextButton {
    [self.csView scrollToNext];

}
- (void)clickButton {
   self.pagePath = [self.delegate getDataPathWithOutSuffix:self.currentNumber];
    if (IS_SAME) {
        NSString* path =  [NSString stringWithContentsOfFile:[self.pagePath stringByAppendingString:@".mp3"] encoding: NSASCIIStringEncoding error:nil];
        self.player.path = path;
       
    } else {
        NSRange range = [self.pagePath rangeOfString:@"/" options:NSBackwardsSearch];
        if (range.location != NSNotFound) {
            NSString* filename = [self.pagePath substringFromIndex:range.location+1];
            NSRange headerrange = [filename rangeOfString:HEADERSTRING];
            if (headerrange.location != NSNotFound) {
                NSString* textName = [filename substringFromIndex:headerrange.location+headerrange.length];
                NSRange chRange = [textName rangeOfString:@"-"];
                if (chRange.location != NSNotFound) {
                    NSInteger first = [[textName substringToIndex:chRange.location] integerValue];
                    NSInteger second = [[textName substringFromIndex:(chRange.location+1)] integerValue];
                    NSString* textfilename = [NSString stringWithFormat:@"%d-%d", first - RLATIONOFFSET, second + RLATIONOFFSET];
                    NSString* textPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingFormat:@"%@", @"/Data/Voice/"];
                    NSString* path = [textPath stringByAppendingFormat:@"%@.mp3", textfilename];
                    self.player.path = path;
                    
                }
            }
        }
        
    }
    if (self.player.path == nil) {
        return;
    }
        NSTimeInterval inter = [self.player getTimeInterval];
        LessonView* lessonView = (LessonView*)[self.csView getCurrentView];
        if (lessonView != nil) {
            lessonView.timeInterval = inter;
        }
        NSLog(@"%@", lessonView.srcLabel.text);
        if (self.buttonStatus ==
            0) {
            // PLAY
            self.buttonStatus = 1;
            [self.playButton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
            [self.player play];
            [lessonView startAnimation];
        } else {
            // PAUSE
            self.buttonStatus = 0;
            [_playButton setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
             [self.player pause];
            [lessonView pause];
        }
   
}

- (void)doNextPlay {
    if (self.currentNumber != self.totalCount) {
        [self.csView scrollToNext];
        [self performSelector:@selector(clickButton) withObject:nil afterDelay:0.5];
    }

}

- (void)didPlayNotification:(NSNotification*)object {
    self.buttonStatus = 0;
    [_playButton setImage:[UIImage imageNamed:@"Play.png"] forState:UIControlStateNormal];
    [_playButton setImage:[UIImage imageNamed:@"PlayHot.png"] forState:UIControlStateSelected];
    [_playButton setImage:[UIImage imageNamed:@"PlayHot.png"] forState:UIControlStateHighlighted];
    [self performSelector:@selector(doNextPlay) withObject:nil afterDelay:1.0];

 }

@end
