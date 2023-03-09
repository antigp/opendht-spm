//
//  Header.h
//  
//
//  Created by Eugene Antropov on 21.02.2023.
//

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

#include "opendht_c.h"
#include <opendht/def.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>

typedef struct dht_value_type dht_value_type;

typedef bool (*dht_filter_cb)(const dht_value* value, void* user_data);


// Get
OPENDHT_C_PUBLIC void dht_runner_get_with_filter(dht_runner* r, const dht_infohash* h, dht_get_cb cb, dht_done_cb done_cb, void* cb_user_data, dht_filter_cb filter_cb, const char* where) ;
OPENDHT_C_PUBLIC dht_op_token* dht_runner_listen_with_filter(dht_runner* r, const dht_infohash* h, dht_value_cb cb, dht_shutdown_cb done_cb, void* cb_user_data, dht_filter_cb filter_cb, const char* w);

// Value
OPENDHT_C_PUBLIC void dht_value_set_id(dht_value* data, dht_value_id id);
OPENDHT_C_PUBLIC dht_value* dht_value_new_with_type(const uint8_t* data, size_t size, uint16_t type);
OPENDHT_C_PUBLIC uint16_t dht_value_get_valuetype_id(const dht_value* t);


// ValueTypes
OPENDHT_C_PUBLIC void dht_register_value_type(dht_runner* r, dht_value_type* t);
OPENDHT_C_PUBLIC dht_value_type* dht_value_type_default_userdata();
OPENDHT_C_PUBLIC uint16_t dht_get_valuetype_id(const dht_value_type* t);
OPENDHT_C_PUBLIC const char* dht_get_valuetype_name(const dht_value_type* t);
typedef bool (*dht_store_policy)(dht_infohash key, const dht_value* value, const dht_infohash from, const struct sockaddr* addr, socklen_t addr_len, void* cb_user_data);
typedef bool (*dht_edit_policy)(dht_infohash key, const dht_value* old_value, const dht_value* new_value, const dht_infohash from, const struct sockaddr* addr, socklen_t addr_len, void* cb_user_data);
OPENDHT_C_PUBLIC dht_value_type* dht_valuetype_new(uint16_t id, const char* name, uint32_t duration, dht_store_policy sp, dht_edit_policy ep, void* cb_user_data);

// Node status
typedef struct dht_node_status dht_node_status;
struct OPENDHT_PUBLIC dht_node_status {
    unsigned good_nodes;
    unsigned dubious_nodes;
    unsigned cached_nodes;
    unsigned incoming_nodes;
    unsigned table_depth;
    unsigned searches;
    unsigned node_cache_size;
};

typedef struct dht_node_info dht_node_info;
struct OPENDHT_PUBLIC dht_node_info {
    dht_infohash id;
    dht_infohash node_id;
    dht_node_status ipv4;
    dht_node_status ipv6;
    size_t ongoing_ops;
    size_t storage_values;
    size_t storage_size;
    in_port_t bound4;
    in_port_t bound6;
};
OPENDHT_C_PUBLIC dht_node_info dht_get_node_info(dht_runner* r);

typedef void (*dht_change_status)(const char* ipv4, const char* ipv6, void* user_data);
OPENDHT_C_PUBLIC void dht_on_status_changed(dht_runner* r, dht_change_status done_cb, void* cb_user_data);


//PHT
typedef struct PHTKeySpecValue
{
    const char* key;
    size_t lenght;
} PHTKeySpecValue;

typedef struct PHTKeySpecInfo
{
    // Contains an array of pointers to items.
    PHTKeySpecValue* items;
    int count;
} PHTKeySpecInfo;
typedef struct dht_pht dht_pht;

typedef struct PHTIndexValue
{
    dht_infohash hash;
    uint64_t objectId;
} PHTIndexValue;

typedef struct PHTKeyData
{
    // Contains an array of pointers to items.
    char* key;
    const uint8_t* data;
    size_t dataSize;
} PHTKeyData;

typedef struct PHTKeyArray
{
    // Contains an array of pointers to items.
    PHTKeyData* items;
    int count;
} PHTKeyArray;
typedef void (*pht_value_cb)(PHTIndexValue value, void* user_data);
typedef void (*dht_done_cb)(bool ok, void* user_data);

OPENDHT_C_PUBLIC dht_pht* dht_create_pht(dht_runner* r, char *name, PHTKeySpecInfo info);
OPENDHT_C_PUBLIC void pht_insert(dht_pht* p, PHTKeyArray k, PHTIndexValue v, dht_done_cb done_cb, void *user_data);
OPENDHT_C_PUBLIC void pht_lookup(dht_pht* p, PHTKeyArray k, pht_value_cb value_cb, dht_done_cb done_cb, bool exact_match, void *user_data);
#ifdef __cplusplus
}
#endif
