#ifndef BACON_IMAGE_HH
#define BACON_IMAGE_HH

#include <iostream>
using std::cout;
using std::endl;

#include "Bacon/Array.hh"

namespace Bacon {

template <class NumT>
class Image2D : public Array2D<NumT> {
  public:
    Image2D()
        : Array2D<NumT>()
    {
        // do nothing
    }

    Image2D(int yy, int xx)
        : Array2D<NumT>()
    {
        this->data_rows = yy;
        this->data_cols = xx;
        reallocate(yy * xx);
    }

    void 
    reallocate(int size)
    {
        assert(this->ctx != 0);
        this->data_size = size;
        this->data_ptr = boost::shared_array<NumT>(new NumT[this->data_size]);
        this->on_gpu = false;
        this->valid_data = false;
        image = cl::Image2D(this->ctx->ctx, 0, image_format(),
            this->data_cols, this->data_rows, 0, 0);
    }

    cl::Image2D data()
    {
        if (!this->on_gpu)
            send_dev();
        return image;
    }

    cl::ImageFormat image_format();

    void send_dev()
    {
        assert(this->ctx != 0);
        this->on_gpu = true;

        cl::size_t<3> origin;
        origin[0] = 0;
        origin[1] = 0;
        origin[2] = 0;
        cl::size_t<3> region;
        region[0] = this->data_cols;
        region[1] = this->data_rows;
        region[2] = 1;
        
        this->ctx->queue.enqueueWriteImage(image, true, origin, region, 
            0, 0, this->data_ptr.get());
    }

    void recv_dev()
    {
        assert(this->ctx != 0);
        this->on_gpu = false;

        cl::size_t<3> origin;
        origin[0] = 0;
        origin[1] = 0;
        origin[2] = 0;
        cl::size_t<3> region;
        region[0] = this->data_cols;
        region[1] = this->data_rows;
        region[2] = 1;

        this->ctx->queue.enqueueReadImage(image, true, origin, region, 
            0, 0, this->data_ptr.get());
    }

 protected:
    cl::Image2D image;
};

template<> 
inline
cl::ImageFormat
Image2D<cl_uchar>::image_format()
{
    return cl::ImageFormat(CL_R, CL_UNSIGNED_INT8);
}

template<>
inline
cl::ImageFormat
Image2D<cl_ushort>::image_format()
{
    return cl::ImageFormat(CL_R, CL_UNSIGNED_INT16);
}

template<>
inline
cl::ImageFormat
Image2D<cl_short>::image_format()
{
    return cl::ImageFormat(CL_R, CL_SIGNED_INT16);
}

template<>
inline
cl::ImageFormat
Image2D<cl_ulong>::image_format()
{
    return cl::ImageFormat(CL_RGBA, CL_UNSIGNED_INT16);
}

template <class NumT>
class Image3D : public Array3D<NumT> {
  public:
    Image3D()
        : Array3D<NumT>()
    {
        // do nothing
    }

    Image3D(int zz, int yy, int xx)
        : Array3D<NumT>()
    {
        this->data_deep = zz;
        this->data_rows = yy;
        this->data_cols = xx;
        reallocate(zz * yy * xx);
    }

    virtual void 
    reallocate(int size)
    {
        assert(this->ctx != 0);
        this->data_size = size;
        this->data_ptr = boost::shared_array<NumT>(new NumT[this->data_size]);
        this->on_gpu = false;
        this->valid_data = false;
        image = cl::Image3D(this->ctx->ctx, CL_MEM_READ_WRITE, image_format(),
            this->data_cols, this->data_rows, this->data_deep, 0, 0);
    }

    cl::Image3D data()
    {
        if (!this->on_gpu)
            send_dev();
        return image;
    }

    cl::ImageFormat image_format();

    void send_dev()
    {
        assert(this->ctx != 0);
        this->on_gpu = true;

        cl::size_t<3> origin;
        origin[0] = 0;
        origin[1] = 0;
        origin[2] = 0;
        cl::size_t<3> region;
        region[0] = this->data_cols;
        region[1] = this->data_rows;
        region[2] = this->data_deep;
        
        this->ctx->queue.enqueueWriteImage(image, true, origin, region, 
            0, 0, this->data_ptr.get());
    }

    void recv_dev()
    {
        assert(this->ctx != 0);
        this->on_gpu = false;

        cl::size_t<3> origin;
        origin[0] = 0;
        origin[1] = 0;
        origin[2] = 0;
        cl::size_t<3> region;
        region[0] = this->data_cols;
        region[1] = this->data_rows;
        region[2] = this->data_deep;

        this->ctx->queue.enqueueReadImage(image, true, origin, region, 
            0, 0, this->data_ptr.get());
    }

 protected:
    cl::Image3D image;
};

template<> 
inline
cl::ImageFormat
Image3D<cl_uchar>::image_format()
{
    return cl::ImageFormat(CL_R, CL_UNSIGNED_INT8);
}

template<>
inline
cl::ImageFormat
Image3D<cl_ushort>::image_format()
{
    return cl::ImageFormat(CL_R, CL_UNSIGNED_INT16);
}

template<>
inline
cl::ImageFormat
Image3D<cl_ulong>::image_format()
{
    return cl::ImageFormat(CL_RGBA, CL_UNSIGNED_INT16);
}

} // namespace Bacon

#endif
