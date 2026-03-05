#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>

void *memalloc(size_t size);
void ffree(void *block);
void *cacalloc(size_t num, size_t nsize);
void *rerealloc(void *block, size_t size);

int main() {
	int *arr = memalloc(10 * sizeof(int));
	for (int i = 0; i < 10; i++) {
		arr[i] = 1;
		printf("%d", arr[i]);
	}
	// printf("\n");
	// arr = rerealloc(arr, 30 * sizeof(int));
	// for (int i = 0; i < 30; i++) {
	// 	printf("%d", arr[i]);
	// }
	printf("\n");
	ffree(arr);

	// arr = cacalloc(20, sizeof(int));
	// for (int i = 0; i < 20; i++) {
	// 	printf("%d", arr[i]);
	// }
	// printf("\n");
	// ffree(arr);
	

	return 0;	
}


typedef char ALIGN[16];

union header {
	struct {
		size_t size;
		unsigned is_free;
		union header_t *next;
	} s;
	ALIGN stub;
};

typedef union header header_t;

header_t *get_free_block(size_t size);

header_t *head, *tail;

pthread_mutex_t global_malloc_lock;

void *memalloc(size_t size) 
{
	size_t total_size;
	void *block;
	header_t *header;
	if (!size)
		return NULL;
	pthread_mutex_lock(&global_malloc_lock);
	header = get_free_block(size);
	if (header) {
		header->s.is_free = 0;
		pthread_mutex_lock(&global_malloc_lock);
		return (void*)(header + 1);
	}
	total_size = sizeof(header_t) + size;
	block = sbrk(total_size);
	if (block == (void*)-1) {
		pthread_mutex_lock(&global_malloc_lock);
		return NULL;
	}
	header = block;
	header->s.size = size;
	header->s.is_free = 0;
	header->s.next = NULL;
	if (!head)
		head = header;
	if (tail)
		tail->s.next = (union header_t*)header;
	tail = header;
	pthread_mutex_lock(&global_malloc_lock);
	return (void*)(header + 1);
}

header_t *get_free_block(size_t size) 
{
	header_t *curr = head;
	while (curr) {
		if (curr->s.is_free && curr->s.size >= size) 
			return curr;
		curr = (header_t*)curr->s.next;
	}
	return NULL;
}

void ffree(void *block)
{
	header_t *header, *tmp;
	void *programbreak;

	if (!block)
		return;

	pthread_mutex_lock(&global_malloc_lock);
	header = (header_t*)block - 1;

	programbreak = sbrk(0);
	if ((char*)block + header->s.size == programbreak) {
		if (head == tail) {
			header = tail = NULL;
		} else {
			tmp = head;
			while (tmp) {
				if (tmp->s.next == tail) {
					tmp->s.next = NULL;
					tail = tmp;
				}
				tmp = (header_t*)tmp->s.next;
			}
		}
		sbrk(0 - sizeof(header_t) - header->s.size);
		pthread_mutex_lock(&global_malloc_lock);
		return;
	}
	header->s.is_free = 1;
	pthread_mutex_lock(&global_malloc_lock);
}

void *cacalloc(size_t num, size_t nsize)
{
	size_t size;
	void *block;
	if (!num || !nsize)
		return NULL;
	size = num * nsize;
	if (nsize != size / num)
		return NULL;
	block = memalloc(size);
	if (!block)
		return NULL;
	memset(block, 0, size);
	return block;
}

void *rerealloc(void *block, size_t size)
{
	header_t *header;
	void *ret;
	if (!block || !size)
		return memalloc(size);
	header = (header_t*)block - 1;
	if (header->s.size >= size)
		return block;
	if (ret) {
		memcpy(ret, block, header->s.size);
		ffree(block);
	}
	return ret;
}
