/* ====================================================================
 * Copyright (c) 2014 - 2017 The GmSSL Project.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * 3. All advertising materials mentioning features or use of this
 *    software must display the following acknowledgment:
 *    "This product includes software developed by the GmSSL Project.
 *    (http://gmssl.org/)"
 *
 * 4. The name "GmSSL Project" must not be used to endorse or promote
 *    products derived from this software without prior written
 *    permission. For written permission, please contact
 *    guanzhi1980@gmail.com.
 *
 * 5. Products derived from this software may not be called "GmSSL"
 *    nor may "GmSSL" appear in their names without prior written
 *    permission of the GmSSL Project.
 *
 * 6. Redistributions of any form whatsoever must retain the following
 *    acknowledgment:
 *    "This product includes software developed by the GmSSL Project
 *    (http://gmssl.org/)"
 *
 * THIS SOFTWARE IS PROVIDED BY THE GmSSL PROJECT ``AS IS'' AND ANY
 * EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE GmSSL PROJECT OR
 * ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 * ====================================================================
 */

#include <string.h>
#include "sm3.h"
#include "byteorder.h"
#include "time.h"
#include "windows.h"
#include "svdpi.h"
#include "dpiheader.h"
#include "vpi_user.h"

void sm3_init(sm3_ctx_t *ctx)
{
	memset(ctx, 0, sizeof(*ctx));
	ctx->digest[0] = 0x7380166F;
	ctx->digest[1] = 0x4914B2B9;
	ctx->digest[2] = 0x172442D7;
	ctx->digest[3] = 0xDA8A0600;
	ctx->digest[4] = 0xA96F30BC;
	ctx->digest[5] = 0x163138AA;
	ctx->digest[6] = 0xE38DEE4D;
	ctx->digest[7] = 0xB0FB0E4E;
}

void sm3_update(sm3_ctx_t *ctx, const unsigned char *data, size_t data_len)
{
	if (ctx->num) {
		unsigned int left = SM3_BLOCK_SIZE - ctx->num;
		if (data_len < left) {
			memcpy(ctx->block + ctx->num, data, data_len);
			ctx->num += data_len;
			return;
		} else {
			memcpy(ctx->block + ctx->num, data, left);
			sm3_compress(ctx->digest, ctx->block);
			ctx->nblocks++;
			data += left;
			data_len -= left;
		}
	}
	while (data_len >= SM3_BLOCK_SIZE) {
		sm3_compress(ctx->digest, data);
		ctx->nblocks++;
		data += SM3_BLOCK_SIZE;
		data_len -= SM3_BLOCK_SIZE;
	}
	ctx->num = data_len;
	if (data_len) {
		memcpy(ctx->block, data, data_len);
	}
}

void sm3_final(sm3_ctx_t *ctx, unsigned char *digest)
{
	int i;
	unsigned int *pdigest = (unsigned int *)digest;
	unsigned int *count = (unsigned int *)(ctx->block + SM3_BLOCK_SIZE - 8);

	ctx->block[ctx->num] = 0x80;

	if (ctx->num + 9 <= SM3_BLOCK_SIZE) {
		memset(ctx->block + ctx->num + 1, 0, SM3_BLOCK_SIZE - ctx->num - 9);
	} else {
		memset(ctx->block + ctx->num + 1, 0, SM3_BLOCK_SIZE - ctx->num - 1);
		sm3_compress(ctx->digest, ctx->block);
		memset(ctx->block, 0, SM3_BLOCK_SIZE - 8);
	}

	count[0] = cpu_to_be32((unsigned int)(ctx->nblocks >> 23));
	count[1] = cpu_to_be32((unsigned int)(ctx->nblocks << 9) + (ctx->num << 3));

	sm3_compress(ctx->digest, ctx->block);
	for (i = 0; i < sizeof(ctx->digest)/sizeof(ctx->digest[0]); i++) {
		pdigest[i] = cpu_to_be32(ctx->digest[i]);
	}
}

#define ROTL(x,n)  (((x)<<(n)) | ((x)>>(32-(n))))
#define P0(x) ((x) ^ ROTL((x), 9) ^ ROTL((x),17))
#define P1(x) ((x) ^ ROTL((x),15) ^ ROTL((x),23))

#define FF00(x,y,z)  ((x) ^ (y) ^ (z))
#define FF16(x,y,z)  (((x)&(y)) | ((x)&(z)) | ((y)&(z)))
#define GG00(x,y,z)  ((x) ^ (y) ^ (z))
#define GG16(x,y,z)  (((x)&(y)) | ((~(x))&(z)))

#define T00 0x79CC4519
#define T16 0x7A879D8A

void sm3_compress(unsigned int digest[8], const unsigned char block[64])
{
	unsigned int A = digest[0];
	unsigned int B = digest[1];
	unsigned int C = digest[2];
	unsigned int D = digest[3];
	unsigned int E = digest[4];
	unsigned int F = digest[5];
	unsigned int G = digest[6];
	unsigned int H = digest[7];
	const unsigned int *pblock = (const unsigned int *)block;
	unsigned int W[68], W1[64];
	unsigned int SS1, SS2, TT1, TT2;
	int j;

	for (j = 0; j < 16; j++)
		W[j] = cpu_to_be32(pblock[j]);

	for (; j < 68; j++)
		W[j] = P1(W[j - 16] ^ W[j - 9] ^ ROTL(W[j - 3], 15))
			^ ROTL(W[j - 13], 7) ^ W[j - 6];

	for(j = 0; j < 64; j++)
		W1[j] = W[j] ^ W[j + 4];

	for (j = 0; j < 16; j++) {
		SS1 = ROTL((ROTL(A, 12) + E + ROTL(T00, j)), 7);
		SS2 = SS1 ^ ROTL(A, 12);
		TT1 = FF00(A, B, C) + D + SS2 + W1[j];
		TT2 = GG00(E, F, G) + H + SS1 + W[j];
		D = C;
		C = ROTL(B, 9);
		B = A;
		A = TT1;
		H = G;
		G = ROTL(F, 19);
		F = E;
		E = P0(TT2);
	}

	for (; j < 64; j++) {
		SS1 = ROTL((ROTL(A, 12) + E + ROTL(T16, j % 32)), 7);
		SS2 = SS1 ^ ROTL(A, 12);
		TT1 = FF16(A, B, C) + D + SS2 + W1[j];
		TT2 = GG16(E, F, G) + H + SS1 + W[j];
		D = C;
		C = ROTL(B, 9);
		B = A;
		A = TT1;
		H = G;
		G = ROTL(F, 19);
		F = E;
		E = P0(TT2);
	}

	digest[0] ^= A;
	digest[1] ^= B;
	digest[2] ^= C;
	digest[3] ^= D;
	digest[4] ^= E;
	digest[5] ^= F;
	digest[6] ^= G;
	digest[7] ^= H;
}

void sm3(const unsigned char *msg, size_t msglen,
	unsigned char dgst[SM3_DIGEST_LENGTH])
{
	sm3_ctx_t ctx;

	sm3_init(&ctx);
	sm3_update(&ctx, msg, msglen);
	sm3_final(&ctx, dgst);

	memset(&ctx, 0, sizeof(sm3_ctx_t));
}

unsigned char * generate_msg(unsigned int len)
{
    unsigned char *msg_handle;
    unsigned char *tmp;
    msg_handle = malloc(len);

    if(!msg_handle)
        return NULL;
    tmp = msg_handle;
    memset(msg_handle, 0, len);
    unsigned int tot_len = len;
    while(tot_len--)
    {
        *tmp = 0x41;
        tmp++;
    }
    return msg_handle;
}

/*
    输入1个64bit的数据进行SM3运算，以4个64比特指针返回SM3结果
*/
void sm3_rfr_64b(
    uint64_t *o0,
    uint64_t *o1,
    uint64_t *o2,
    uint64_t *o3
    ,
    //uint64_t i0
    const svBitVecVal* i0
)
{
    unsigned char boo;
    // for (int n = 63; n >= 0; n--) {
    //     if(i0[n])
    //         boo += 1;
    //     boo<<1;
    // }
    boo = *i0;//但是赋值给 boo 并使用就会报错
	printf("msg:%llX\n", boo);//打印 ok

    unsigned char * ptr = boo;
    unsigned char res[32];
    //unsigned char *str = generate_msg(8);
    sm3(ptr, 1, res);
    unsigned long long *long_ptr = (unsigned long long*)res;

    *o0 = *(long_ptr + 0);
    *o1 = *(long_ptr + 1);
    *o2 = *(long_ptr + 2);
    *o3 = *(long_ptr + 3);

	for (int j = 0; j < 4; j++)
	{
		printf("%llX:\n",(*long_ptr));
        long_ptr+=1;
    }
}

void sm3_c(const int len,const svOpenArrayHandle  data_in,const svOpenArrayHandle  res_array)
{
    #define BUFF_LEN 1050

    int i, * data;
    int * res_array_ptr;
    unsigned char ptr_u8[BUFF_LEN];
    int data_in_val;
    unsigned char res[32];
    int sm3_cal_len;

    //运算长度
    sm3_cal_len = len <= BUFF_LEN ? len : BUFF_LEN;
    sm3_cal_len = sm3_cal_len <= svSize(data_in,1) ? len : svSize(data_in,1);
    printf("C array len:%d\n",sm3_cal_len);

    //获取开放数组指针
    data = (int * )svGetArrayPtr(data_in);
    res_array_ptr = (int * )svGetArrayPtr(res_array);

    //ptr_u8 = malloc(20);

    for(int i = 0 ; i < sm3_cal_len;i++)
    {
        data_in_val = *(int *)svGetArrElemPtr1(data_in,i);    

        ptr_u8[i] =  data_in_val & 0xff;
        // printf("C array[%d]:%x\n",i,ptr_u8[i]);
    }

    sm3(ptr_u8, sm3_cal_len, res);

    //计算结果
    for(int i = 0 ; i < 8;i++)
    {
        res_array_ptr[i] = res[4*i] << 24 | res[4*i+1] << 16 | res[4*i+2] << 8 | res[4*i+3];
        printf("C res array[%d]:%x\n",i,res_array_ptr[i]);
    }

    //free(ptr_u8);
}

int sm3_cal(int msg_len)
{
	unsigned int len = msg_len;
	
	unsigned char *str = generate_msg(len);
	unsigned char res[32];

	unsigned long long start,end;
	start = clock();
	sm3(str, len, res);
	// for (int i = 0; i < 1000000;i++){
	// };
	end = clock();
	printf("time=%lld\n",end-start);
	unsigned long long *long_ptr = (unsigned long long*)res;
	printf("i=%d\n", len);
	for (int j = 0; j < 4; j++)
	{
		printf("%llX:\n",(*long_ptr));
        long_ptr+=1;
    }
	// printf("ei:%x%x\n",*((unsigned char *)(long_ptr-4)),*((unsigned char *)(long_ptr-4)+1));
	// if(*((unsigned char *)(long_ptr-4)) == 0x2A
	// 		&& *((unsigned char *)(long_ptr-4)+1) == 0x86)
	// 	printf("ei");
	// }
	//system("pause");
	
}
