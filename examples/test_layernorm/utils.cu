#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include "utils.cuh"
#include <cuda_runtime.h>
#include <cublas_v2.h>
#include <cuda_fp16.h>
#include <stdbool.h>

#define CEIL_DIV(m,n) ( (m) + (n) - 1 ) / (n)
void print_matrix(const FLOAT *A, int m, int n){
    int i;
    printf("[");
    for (i = 0; i < m * n; i++){
        if ((i + 1) % n == 0) printf("%5.2f ",__half2float(A[i]));
        else printf("%5.2f, ", __half2float(A[i]));
        if ((i + 1) % n == 0){
            if (i + 1 < m * n) printf(";\n");
        }
    }
    printf("]\n");
}

void print_matrix(const float *A, int m, int n){
    int i;
    printf("[");
    for (i = 0; i < m * n; i++){
        if ((i + 1) % n == 0) printf("%5.2f ",(A[i]));
        else printf("%5.2f, ", (A[i]));
        if ((i + 1) % n == 0){
            if (i + 1 < m * n) printf(";\n");
        }
    }
    printf("]\n");
}


void randomize_matrix(FLOAT* mat, int N){
    srand(time(NULL)); int i;
    for (i = 0; i < N; i++) {
        FLOAT tmp = (rand() % 2 == 0) ? (FLOAT)(rand() % 5) : (FLOAT)((rand() % 5) * -1);
        // FLOAT tmp = i ;
        mat[i] = tmp;
    }
}

void randomize_matrix_plus_one(FLOAT* mat, int N){
    srand(time(NULL)); int i;
    for (i = 0; i < N; i++) {
        FLOAT tmp = (rand() % 2 == 0) ? (FLOAT)((rand() % 5) + 1) : (FLOAT)(((rand() % 5) + 1) * -1);
        // FLOAT tmp = i + 1;
        mat[i] = tmp;
    }
}

void randomize_matrix_plus_one(float* mat, int N){
    srand(time(NULL)); int i;
    for (i = 0; i < N; i++) {
        float tmp = (rand() % 2 == 0) ? (float)((rand() % 5) + 1) : (float)(((rand() % 5) + 1) * -1);
        // FLOAT tmp = i + 1;
        mat[i] = tmp;
    }
}

void randomize_matrix_zero(float* mat, int N){
    srand(time(NULL)); int i;
    for (i = 0; i < N; i++) {
        // FLOAT tmp = (rand() % 2 == 0) ? (FLOAT)(rand() % 5) : (FLOAT)((rand() % 5) * -1);
        float tmp = 0;
        mat[i] = tmp;
    }
}

void randomize_matrix_zero(FLOAT* mat, int N){
    srand(time(NULL)); int i;
    for (i = 0; i < N; i++) {
        // FLOAT tmp = (rand() % 2 == 0) ? (FLOAT)(rand() % 5) : (FLOAT)((rand() % 5) * -1);
        FLOAT tmp = 0;
        mat[i] = tmp;
    }
}

void randomize_matrix_one(FLOAT* mat, int N){
    srand(time(NULL)); int i;
    for (i = 0; i < N; i++) {
        FLOAT tmp = 1;
        mat[i] = tmp;
    }
}

void randomize_matrix_one(float* mat, int N){
    srand(time(NULL)); int i;
    for (i = 0; i < N; i++) {
        float tmp = 1;
        mat[i] = tmp;
    }
}

void randomize_matrix(float* mat, int N){
    srand(time(NULL)); int i;
    for (i = 0; i < N; i++) {
        float tmp = (rand() % 2 == 0) ? (float)(rand() % 5) : (float)((rand() % 5) * -1);
        // float tmp = i;
        mat[i] = tmp;
    }
}

double get_sec(){
    struct timeval time;
    gettimeofday(&time, NULL); 
    return (time.tv_sec + 1e-6 * time.tv_usec);
}

bool verify_matrix(FLOAT *mat1, FLOAT *mat2, int n){
    double diff = 0.0;
    int i;
    int err_cnt = 0;
    for (i = 0; mat1 + i && mat2 + i && i < n; i++){
        diff = fabs( (double)mat1[i] - (double)mat2[i] ) / fabs((double)mat1[i]);
        if (diff > 1e-4) {
            if (err_cnt < 5) printf("error. %5.2f,%5.2f,%d\n", (double)mat1[i],(double)mat2[i],i);
            err_cnt++;
        }
    }
    return (err_cnt == 0);
}

bool verify_matrix(float *mat1, float *mat2, int n){
    double diff = 0.0;
    int i;
    int err_cnt = 0;
    for (i = 0; mat1 + i && mat2 + i && i < n; i++){
        diff = fabs( (double)mat1[i] - (double)mat2[i] ) / fabs((double)mat1[i]);
        if (diff > 5e-3) {
            if (err_cnt < 5) 
                printf("error. %8.5f,%8.5f,%d\n", (double)mat1[i],(double)mat2[i],i);
            err_cnt++;
        }
    }
    return (err_cnt == 0);
}

void copy_matrix(FLOAT *src, FLOAT *dest, int n){
    int i;
    for (i = 0; src + i && dest + i && i < n; i++) *(dest + i) = *(src + i);
    if (i != n) printf("copy failed at %d while there are %d elements in total.\n", i, n);
}
