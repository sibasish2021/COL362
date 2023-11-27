#include <bits/stdc++.h>
using namespace std;
typedef pair<string,int> psi;
long key;
int available_space=1024*1024*400;



void get_partial_data(vector<string> &v, int av_sp,FILE* fl){
    while(av_sp>0 && key>0){
        string s="";
        char c;
        c = fgetc(fl);
        if(c!=EOF){
            while (c != '\n'){
                s += c;
                c = fgetc(fl);
            }
        }
        v.push_back(s);
        av_sp-=(32+s.size());
        key--;
    }
}

void getData(vector<string> &v, int av_sp, FILE* fl, long &n){
    while(av_sp>0 && n>0){
        string s="";
        char c;
        c = fgetc(fl);
        if(c!=EOF){
            while (c != '\n'){
                s += c;
                c = fgetc(fl);
            }
        }
        v.push_back(s);
        av_sp-=(32+s.size());
        n--;
    }
}

void write_file(const char* filename, vector<string> v){
    FILE* fl=freopen(filename,"w",stdout);
    for(int i=0;i<v.size();i++){
        cout<<v[i];
        cout<<"\n";
    }
}


void merge(int l,int r,vector<string> &fl_nm,vector<long> &fl_sz,string &nm){
    int sz=r-l+1;
    vector<long> ptr(sz,0);
    vector<vector<string>> str;
    vector<FILE*> dup_ipt;
    for(int i=l;i<=r;i++){
        dup_ipt.push_back(fopen(fl_nm[i].c_str(),"r"));
    }
    for(int i=l;i<=r;i++){
        vector<string> temp;
        getData(temp,available_space/sz,dup_ipt[i-l],fl_sz[i]);
        str.push_back(temp);
        temp.clear();
    }
    FILE* fl=freopen(nm.c_str(),"w",stdout);
    priority_queue<psi,vector<psi>,greater<psi>> pr;
    for(int i=0;i<sz;i++){
        pr.push(make_pair(str[i][ptr[i]],i));
    }
    while(!pr.empty()){
        // sort(pr.begin(),pr.end(),greater<psi>());
        psi p=pr.top();
        pr.pop();
        cout<<p.first;
        cout<<"\n";
        ptr[p.second]++;
        if(ptr[p.second]>=str[p.second].size()){
            str[p.second].clear();
            ptr[p.second]=0;
            if(fl_sz[p.second+l]>0){
                vector<string> temp1;
                getData(temp1,available_space/sz,dup_ipt[p.second],fl_sz[p.second+l]);
                str[p.second]=temp1;
                temp1.clear();
            }
        }
        if(str[p.second].size()>0)
        {
            pr.push(make_pair(str[p.second][ptr[p.second]],p.second));
        }
    }
}

int external_merge_sort_withstop (const char* input , const char *output , const long key_count , const int k =2 , const int num_merges = 0){
    int dup_num_merges=num_merges;
    int flag=0;
    if(dup_num_merges>0) flag=1;
    vector<string> file_name;
    vector<long> file_size;
    key=key_count;
    FILE* ipt=fopen(input,"r");
    while(key>0){
        int current_iteration=file_name.size()+1;
        vector<string> temp;
        int dup_space=available_space;
        get_partial_data(temp,dup_space,ipt);
        file_size.push_back(temp.size());
        sort(temp.begin(),temp.end());
        string name="temp.0."+to_string(current_iteration);
        const char* dup_name=("temp.0."+to_string(current_iteration)).c_str();
        file_name.push_back(name);
        if(file_name.size()==1 && key==0) write_file(output,temp);
        write_file(dup_name,temp);
        temp.clear();
    }
    int run_no=1;
    while(file_name.size()>1){
        int left=0;
        int right;
        int qot=file_name.size()/k;
        int rem=file_name.size()%k;
        int num_merge=k*qot;
        vector<string> dup_file_name;
        vector<long> dup_file_size;
        int curr_iter=1;
        if(qot==0||(qot==1 && rem==0)){
            right=file_name.size()-1;
            string temp=output;
            merge(0,right,file_name,file_size,temp); 
            return 0;
        }
        for(int left=0;left<num_merge;left+=k){
            right=left+k-1;
            string name="temp."+to_string(run_no)+"."+to_string(curr_iter);
            dup_file_name.push_back(name);
            int len=0;
            for(int i=left;i<=right;i++){
                len+=file_size[i];
            }
            dup_file_size.push_back(len);
            merge(left,right,file_name,file_size,name);  
            curr_iter++;
            if(dup_num_merges>0){
                dup_num_merges--;
            }
            if(flag==1 && dup_num_merges==0) return 0;     
        }
        if(rem>0){                                 
            for(int i=num_merge;i<file_name.size();i++){
                dup_file_name.push_back(file_name[i]);
                dup_file_size.push_back(file_size[i]);
            }
        }

        file_name.clear();
        file_size.clear();
        file_name=dup_file_name;
        file_size=dup_file_size;
        dup_file_name.clear();
        dup_file_size.clear();
        run_no++;
    }

    return 0;
}
