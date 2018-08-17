PIXFOOD20_PATH := dataset/pixfood20/images
CATS := $(wildcard $(PIXFOOD20_PATH)/*)

CAT_PATH := $(PIXFOOD20_PATH)/$(CAT)
CAT_IMAGES_PATH := $(CAT_PATH)/食物
CAT_MASKED_PATH := $(CAT_PATH)/masked
CAT_CROPED_PATH := $(CAT_PATH)/croped

cat_images := $(wildcard $(CAT_IMAGES_PATH)/*)
cat_croped := $(patsubst $(CAT_IMAGES_PATH)/%,$(CAT_CROPED_PATH)/%,$(cat_images))
cat_masked := $(patsubst $(CAT_IMAGES_PATH)/%,$(CAT_MASKED_PATH)/%,$(cat_images))
inpaint_yml := generative_inpainting/config/inpaint.$(CAT).yml

all: croped flist masked

masked: $(cat_masked)

croped: $(cat_croped)

$(CAT_CROPED_PATH)/%: $(CAT_IMAGES_PATH)/%
	@mkdir -p `dirname $@`
	convert $<  -resize 256x256^ -gravity center -crop 256x256+0+0 $@

$(CAT_MASKED_PATH)/%: $(CAT_CROPED_PATH)/%
	@mkdir -p `dirname $@`
	convert $< -fill White -draw 'rectangle 64,64 192,128' $@

flist: croped
	mkdir -p 'generative_inpainting/data/pixfood20/${CAT}'
	python prepare_dataset.py \
		--folder_path '$(CAT_CROPED_PATH)' \
		--train_filename 'generative_inpainting/data/pixfood20/${CAT}/train.flist' \
		--validation_filename 'generative_inpainting/data/pixfood20/${CAT}/valid.flist'

inpaint-yml:
	mkdir -p generative_inpainting/config
	sed 's/<CAT>/$(CAT)/g' generative_inpainting/inpaint.yml.pixfood20.template > $(inpaint_yml)

train:
	python generative_inpainting/train.py $(inpaint_yml)

debug:
	$(info CATS="$(CATS)")
	$(info CAT_IMAGES_PATH="$(CAT_IMAGES_PATH)")
	$(info cat_images="$(cat_images)")
	$(info cat_croped="$(cat_croped)")


