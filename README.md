# 异步加载网络图片
学习SDWebImage后尝试自己封装              
功能： 异步加载网络图片               
      异步加载网络和本地GIF               
      当图片过大，可设置是否边下边展示图片           
         
PS：只对UIImageView进行添加分类操作加载网络图片。若其他控件也需要异步加载网络图片，可模仿代码中UIImageView的做法。
      
             
第一版：               
简单的对异步加载进行缓存操作，具体的操作如下：     
1.在memory中查看是否已经下载过这张图片，有的话则显示。     
2.在disk中查看是否已经下载过这张图片，有的话则显示。       
3.将下载这张图片url的回调进行缓存，以url为key。      
  （1）当有另外的控件也需要加载这张图片时，取消掉相同的下载操作；       
  （2）将两个控件的回调储存起来，等照片加载完时，调用所有加载这张图片的控件的回调。

第二版：          
缓存从字典换为NSCache，当APP内存不足时可自动清除缓存；            
可加载网络GIF和本地GIF。          

第三版：          
将下载图片的操作：异步线程+dataWithContentsOfURL更改为NSURLSession；              
当图片过大时，可选择是否边下边显示图片。

如何使用？       
1.引入 #import "UIImageView+URLImage.h".      
2.调用 loadURLImageWith:(NSString *)url placeImage:(UIImage *)placeImage 方法即可
