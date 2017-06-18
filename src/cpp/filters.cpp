#include "filters.h"

namespace emvs{

// TODO tune these parameters?
PointCloud radiusFilter(PointCloud& cloud, double search_radius, int min_neighbors)
{
	PointCloud::Ptr cloud_ptr(&cloud);
	PointCloud cloud_filtered;
	pcl::RadiusOutlierRemoval<pcl::PointXYZ> outrem;

	outrem.setInputCloud(cloud_ptr);
	outrem.setRadiusSearch(search_radius);
	outrem.setMinNeighborsInRadius(min_neighbors);
	outrem.filter(cloud_filtered);

	return cloud_filtered;
}

// TODO find a better/faster way to do this
void findMaxVals3D(const std::vector<cv::Mat>& images, cv::Mat& max_layers, cv::Mat& max_vals)
{
	int im_height = images[0].rows;
	int im_width = images[0].cols;

	for(int i=0; i<im_height; i++){
		for(int j=0; j<im_width; j++){
			for(int z=0; z<images.size(); z++){
				if(static_cast<int>(images[z].at<uchar>(i,j)) > static_cast<int>(max_vals.at<uchar>(i,j))){
					max_layers.at<uchar>(i,j) = z;
					max_vals.at<uchar>(i,j) = static_cast<int>(images[z].at<uchar>(i,j));
				}
			}
		}
	}

}

} // end namespace emvs
