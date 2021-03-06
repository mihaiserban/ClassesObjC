#import <Cocoa/Cocoa.h>

extern NSString* SSYLazyViewErrorDomain ;

#define SSY_LAZY_VIEW_ERROR_CODE_COULD_NOT_LOAD_NIB        992611
#define SSY_LAZY_VIEW_ERROR_CODE_LEGACY_COULD_NOT_LOAD_NIB 992613
#define SSY_LAZY_VIEW_ERROR_CODE_LEGACY_COULD_NOT_FIND_NIB 992614
#define SSY_LAZY_VIEW_ERROR_CODE_NO_PAYLOAD                992616

/*
 @brief    Notification which is posted when the payload view is about to be
 loaded.
 
 @details  The notification object is the window in which the SSYLazyView object
 resides.  Note that the loading of the payload, and hence the posting of this
 notification, occurs no more than once during the lifetime of an SSYLazyView
 object.
 */
extern NSString* SSYLazyViewWillLoadPayloadNotification;

/*
 @brief    Notification which is posted after the payload view loads.
 
 @details  Ditto from SSYLazyViewWillLoadPayloadNotification.
 */
extern NSString* SSYLazyViewDidLoadPayloadNotification;

/*
 @brief    A companion to SSYLazyView; provides a method by which a tab view
 item whose view is an instance of SSYLazyView can look down and see if their
 view has been payloaded
 */
@interface NSTabViewItem (SSYLazyPayload)

/*
 @brief    If the receiver's view is an instance of SSYLazyView, returns 
 that view's response to -isPayloaded; otherwise, returns YES
 */
- (BOOL)isViewPayloaded ;

@end

/*
 @brief    View which, upon being moved to a window for the first time, or
 upon demand (-loadWithOwner:), removes all of its original subviews
 ("placeholders") and adds a in their place a single "payload" view which it
 loads from a designated nib
 
 @details  When the receiver loads its nib as a result of being moved to a
 window, the window controller of the window to which it was moved is assigned
 as the file's owner of the nib.  This will cause it to receive -awakeFromNib,
 which has probably happened already.  Therefore, such a window controller's
 -awakeFromNib method typically needs a lockout to prevent it from running more
 than once in an instance.
 
 In the Xcode xib editor, you may have one or more initial placeholder subviews
 in your Lazy View.  For example, you may place a text field with large
 font size that says "Loading Stuff…".  All of these placeholder subviews
 will be removed when the new view is placed in.

 If an error occurs when attempting to load the payload, in either case (when
 receiver is moved to a window or upon -loadWithOwner:), an error dialog
 suggesting that the user reinstall the application is displayed.  We did this
 because these errors should occur very rarely, and in the first case, there
 is no message for us to return an error in.  Yeah, we could have used a 
 delegate or something, but it's not worth the effort.
 */
@interface SSYLazyView : NSView {
    BOOL m_isPayloaded ;
    
    // Needed in Mac OS X 10.8 or later…
    NSArray* m_topLevelObjects ;
}

@property (assign) BOOL isPayloaded ;

/*
 @brief    Returns the name of the nib, without the .nib extension, which will
 be loaded and whose top-level view object become the one and only subview of
 the receiver when the payload view loads.
 
 @details  The default implementation returns @"Internal Error 939-7834".
 You must subclass this class and override this method.
 */
+ (NSString*)lazyNibName ;

/*
 @brief    Creates the receiver's view controller and loads the receiver's
 view, or if these things have not already been done, no op
 
 @details  This method is used to "manually" load the payload, before the
 receiver is moved to a window.
 
 @param    owner  The object which to assign as the File's Owner when the 
 nib is loaded.
 */
- (void)loadWithOwner:(id)owner ;

@end
