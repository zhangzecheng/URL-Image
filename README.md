# -
学习SDWebImage后尝试自己封装
第一版：
简单的对异步加载进行缓存操作，具体的操作如下
1.在memory中查看是否已经下载过这张图片，有的话则显示
2.在disk中查看是否已经下载过这张图片，有的话则显示
3.将下载这张url的block进行缓存
  （1）当有另外的控件也需要加载这张图片时，取消掉相同的下载操作。
  （2）将两个控件的回调储存起来，等照片加载完时，调用所有加载这张图片的控件的回调


如何使用？
1.引入 #import "UIImageView+URLImage.h"
2.调用 loadURLImageWith:(NSString *)url placeImage:(UIImage *)placeImage 方法即可
