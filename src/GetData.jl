module GetData

import Base.close
# package code goes here
export gd_open,
    gd_nfields,
    nvectors,
    field_list,
    vector_list,
    getdata

type dirfile
end

function gd_open(dirfilename::AbstractString)
    flags = 0
    f = ccall( (:gd_open, "libgetdata"), Ptr{dirfile},
        (Cstring, Culong), dirfilename, flags)
end

function close(d::Ptr{dirfile})
    ccall( (:gd_close, "libgetdata"), Cint,
        (Ptr{dirfile}, ), d)
end

function gd_nfields(d::Ptr{dirfile})
    ccall( (:gd_nfields, "libgetdata"), Cuint,
        (Ptr{dirfile}, ), d)
end

function nvectors(d::Ptr{dirfile})
    ccall( (:gd_nvectors, "libgetdata"), Cuint,
        (Ptr{dirfile}, ), d)
end

function decode_stringarray(fptr::Ptr{Cstring}, nstr::Integer)
    const ptrsize = sizeof(fptr)
    [unsafe_string(unsafe_load(fptr+i*ptrsize)) for i=0:nstr-1]
end

function field_list(d::Ptr{dirfile})
    fptr = ccall( (:gd_field_list, "libgetdata"), Ptr{Cstring},
        (Ptr{dirfile}, ), d)
    decode_stringarray(fptr, gd_nfields(d))
end

function vector_list(d::Ptr{dirfile})
    fptr = ccall( (:gd_vector_list, "libgetdata"), Ptr{Cstring},
        (Ptr{dirfile}, ), d)
    decode_stringarray(fptr, gd_nfields(d))
end

#Data may be fetched from a vector field in the dirfile (including metafields) with

# size_t gd_getdata(DIRFILE *dirfile, const char *field_code, off_t first_frame, off_t first_sample, size_t num_frames, size_t num_samples, gd_type_t return_type, void *data_out);

#Here return_type identifies the desired type of the returned data, which need not be the same as the type of the data in the dirfile. For SINDIR fields, return_type must be GD_STRING or GD_NULL. For numeric vector fields, any other value may be used for return_type. Type conversion will be performed as necessary. This function returns the number of samples (not frames or bytes) successfully read, or zero on error. If return_type is GD_NULL, no data is returned, and data_out is ignored; however, the number of samples read is still returned.

function getdata(d::Ptr{dirfile}, field_code::AbstractString, first_frame::Csize_t,
    first_sample::Csize_t, num_frames::Csize_t, num_samples::Csize_t)
    return_type::Cint = 0x84 # float 32
    data = Array{Cfloat}(num_frames*num_samples)
    num_fetched = ccall( (:gd_getdata, "libgetdata"), Csize_t,
        (Ptr{dirfile}, Cstring, Csize_t, Csize_t, Csize_t, Csize_t, Cint, Ref{Cfloat}),
        d, field_code, first_frame, first_sample, num_frames, num_samples, return_type, data)
    (num_fetched, data)
end


end # module
