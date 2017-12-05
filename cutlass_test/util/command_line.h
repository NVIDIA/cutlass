/******************************************************************************
 * Copyright (c) 2011-2017, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are not permitted.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 ******************************************************************************/


#pragma once

/**
 * \file
 * Utility for parsing command line arguments
 */

#include <string>
#include <vector>
#include <sstream>
#include <iostream>
#include <limits>

#include <cuda_runtime.h>
#include <cutlass/util/debug.h>


namespace cutlass {

/******************************************************************************
 * command_line
 ******************************************************************************/

/**
 * Utility for parsing command line arguments
 */
struct command_line
{

    std::vector<std::string>    keys;
    std::vector<std::string>    values;
    std::vector<std::string>    args;
    int                         device_id;
    cudaDeviceProp              device_prop;
    float                       device_giga_bandwidth;
    size_t                      device_free_physmem;
    size_t                      device_total_physmem;

    /**
     * Constructor
     */
    command_line(int argc, const char **argv, int device_id = -1) :
        keys(10),
        values(10),
        device_id(device_id)
    {
        using namespace std;

        for (int i = 1; i < argc; i++)
        {
            string arg = argv[i];

            if ((arg[0] != '-') || (arg[1] != '-'))
            {
                args.push_back(arg);
                continue;
            }

            string::size_type pos;
            string key, val;
            if ((pos = arg.find('=')) == string::npos) {
                key = string(arg, 2, arg.length() - 2);
                val = "";
            } else {
                key = string(arg, 2, pos - 2);
                val = string(arg, pos + 1, arg.length() - 1);
            }

            keys.push_back(key);
            values.push_back(val);
        }

        // Initialize device
        CUDA_PERROR_EXIT(device_init());
    }


    /**
     * Checks whether a flag "--<flag>" is present in the commandline
     */
    bool check_cmd_line_flag(const char* arg_name)
    {
        using namespace std;

        for (int i = 0; i < int(keys.size()); ++i)
        {
            if (keys[i] == string(arg_name))
                return true;
        }
        return false;
    }


    /**
     * Returns number of naked (non-flag and non-key-value) commandline parameters
     */
    template <typename value_t>
    int num_naked_args()
    {
        return args.size();
    }


    /**
     * Returns the commandline parameter for a given index (not including flags)
     */
    template <typename value_t>
    void get_cmd_line_argument(int index, value_t &val)
    {
        using namespace std;
        if (index < args.size()) {
            istringstream str_stream(args[index]);
            str_stream >> val;
        }
    }

    /**
     * Returns the value specified for a given commandline parameter --<flag>=<value>
     */
    template <typename value_t>
    void get_cmd_line_argument(const char *arg_name, value_t &val)
    {
        using namespace std;

        for (int i = 0; i < int(keys.size()); ++i)
        {
            if (keys[i] == string(arg_name))
            {
                istringstream str_stream(values[i]);
                str_stream >> val;
            }
        }
    }


    /**
     * Returns the values specified for a given commandline parameter --<flag>=<value>,<value>*
     */
    template <typename value_t>
    void get_cmd_line_arguments(
        const char *arg_name,
        std::vector<value_t> &vals,
        char sep = ',')
    {
        using namespace std;

        if (check_cmd_line_flag(arg_name))
        {
            // Clear any default values
            vals.clear();

            // Recover from multi-value string
            for (int i = 0; i < keys.size(); ++i)
            {
                if (keys[i] == string(arg_name))
                {
                    string val_string(values[i]);
                    istringstream str_stream(val_string);
                    string::size_type old_pos = 0;
                    string::size_type new_pos = 0;

                    // Iterate <sep>-delimited values
                    value_t val;
                    while ((new_pos = val_string.find(sep, old_pos)) != string::npos)
                    {
                        if (new_pos != old_pos)
                        {
                            str_stream.width(new_pos - old_pos);
                            str_stream >> val;
                            vals.push_back(val);
                        }

                        // skip over delimiter
                        str_stream.ignore(1);
                        old_pos = new_pos + 1;
                    }

                    // Read last value
                    str_stream >> val;
                    vals.push_back(val);
                }
            }
        }
    }


    /**
     * The number of pairs parsed
     */
    int parsed_argc()
    {
        return (int) keys.size();
    }

    /**
     * Initialize device
     */
    cudaError_t device_init()
    {
        cudaError_t error = cudaSuccess;

        do
        {
            int deviceCount;
            if (CUDA_PERROR(error = cudaGetDeviceCount(&deviceCount))) break;

            if (deviceCount == 0) {
                fprintf(stderr, "No devices supporting CUDA.\n");
                exit(1);
            }
            if (device_id < 0)
            {
                get_cmd_line_argument("device", device_id);
            }
            if ((device_id > deviceCount - 1) || (device_id < 0))
            {
                device_id = 0;
            }

            if (CUDA_PERROR(error = cudaSetDevice(device_id))) break;

            if (CUDA_PERROR(error = cudaMemGetInfo(&device_free_physmem, &device_total_physmem))) break;

            if (CUDA_PERROR(error = cudaGetDeviceProperties(&device_prop, device_id))) break;

            if (device_prop.major < 1) {
                fprintf(stderr, "Device does not support CUDA.\n");
                exit(1);
            }

            device_giga_bandwidth = float(device_prop.memoryBusWidth) * device_prop.memoryClockRate * 2 / 8 / 1000 / 1000;

        } while (0);

        return error;
    }


    //-------------------------------------------------------------------------
    // Utility functions
    //-------------------------------------------------------------------------

    /// Tokenizes a comma-delimited list of string pairs delimited by ':'
    static void tokenize(
        std::vector<std::pair<std::string, std::string> > &tokens,
        std::string const &str,
        char delim = ',',
        char sep = ':')
    {
        // Home-built to avoid Boost dependency
        size_t s_idx = 0;
        size_t d_idx = std::string::npos;
        while (s_idx < str.size())
        {
            d_idx = str.find_first_of(delim, s_idx);

            size_t end_idx = (d_idx != std::string::npos ? d_idx : str.size());
            size_t sep_idx = str.find_first_of(sep, s_idx);
            size_t offset = 1;
            if (sep_idx == std::string::npos || sep_idx >= end_idx)
            {
                sep_idx = end_idx;
                offset = 0;
            }

            std::pair<std::string, std::string> item(
                str.substr(s_idx, sep_idx - s_idx),
                str.substr(sep_idx + offset, end_idx - sep_idx - offset));

            tokens.push_back(item);
            s_idx = end_idx + 1;
        }
    }

    /// Tokenizes a comma-delimited list of string pairs delimited by ':'
    static void tokenize(
        std::vector<std::string > &tokens,
        std::string const &str,
        char delim = ',',
        char sep = ':')
    {
        std::vector<std::pair<std::string, std::string> > token_pairs;
        tokenize(token_pairs, str, delim, sep);
        for (auto const &tok : token_pairs)
        {
            tokens.push_back(tok.first);
        }
    }
};


} // namespace cutlass
